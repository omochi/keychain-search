class DumpKeychain
    attr_reader :keychain_regex
    def initialize
        @keychain_regex = /^keychain: "([^"]*)"$/
    end
    def run(keychain, regex)
        cmd = [
            "security",
            "dump-keychain",
            "-d",
            keychain
        ].shelljoin
        output = exec_capture(cmd)
        lines = output.split("\n")
        entries = split_entries(lines)

        class_regex = /^class: (.*)$/
        svce_regex = /^    "svce"<blob>=(.*)/
        x0x7_regex = /^    0x00000007 <blob>=(.*)/ 

        entries = entries.map {|entry|
            is_data_line = false
            for line in entry[:lines]
                if is_data_line
                    is_data_line = false
                    plist_str = read_keychain_value(line)
                    plist = REXML::Document.new(plist_str)
                    entry[:note] = read_note_from_plist(plist)
                    next
                end

                if line == "data:"
                    is_data_line = true
                    next
                end
                m = line.match(class_regex)
                if m
                    entry[:class] = read_keychain_value(m[1])
                    next
                end
                m = line.match(svce_regex)
                if m
                    entry[:original_title] = read_keychain_value(m[1])
                    next
                end
                m = line.match(x0x7_regex)
                if m 
                    entry[:updated_title] = read_keychain_value(m[1])
                    next
                end
            end

            entry[:title] = entry[:updated_title] || entry[:original_title]
            
            entry
        }

        entries = entries.select {|e|
            if e[:title] && e[:title].match(regex)
                next true
            end
            if e[:note] && e[:note].match(regex)
                next true
            end
            false
        }

        entries = entries.sort {|a, b|
            compare_nillables(a[:keychain], b[:keychain]) {|ak, bk|
                if ak != bk
                    next ak <=> bk
                end
                compare_nillables(a[:title], b[:title]) {|at, bt|
                    at <=> bt
                }
            }
        }

        for x in entries
            puts "===="
            puts "keychain: #{x[:keychain]}"
            puts "title: #{x[:title]}"
            puts "--"
            puts x[:note]
        end

        return lines
    end

    def split_entries(lines)
        i = 0
        entries = []
        entry = nil
        while i < lines.length
            line = lines[i]
            i += 1
            m = line.match(keychain_regex)
            if m
                if entry
                    entries << entry
                end
                entry = {
                    keychain: m[1],
                    lines: []
                }
            end
            if ! entry
                next
            end
            entry[:lines] << line
        end
        if entry
            entries << entry
        end
        return entries
    end

    def read_note_from_plist(plist)
        dict = plist.elements["/plist/dict"]

        is_note_line = false
        for item in dict.elements
            if is_note_line
                is_note_line = false
                return item.text
            end
            if item.name == "key"
                if item.text == "NOTE"
                    is_note_line = true
                    next
                end
            end
        end

        return nil
    end
end