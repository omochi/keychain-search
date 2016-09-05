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

        class_regex = /^class: (.*)$/
        svce_regex = /^    "svce"<blob>=(.*)/
        x0x7_regex = /^    0x00000007 <blob>=(.*)/ 
        type_regex = /^    "type"<uint32>=(.*)/

        entries = split_entries(lines).map{|keychain, lines|
            is_data_line = false

            data_str = nil
            class_name = nil
            type = nil
            original_title = nil
            updated_title = nil
            note = nil

            for line in lines
                if is_data_line
                    is_data_line = false
                    data_str = read_keychain_value(line)
                    next
                end

                if line == "data:"
                    is_data_line = true
                    next
                end
                m = line.match(class_regex)
                if m
                    class_name = read_keychain_value(m[1])
                    next
                end
                m = line.match(svce_regex)
                if m
                    original_title = read_keychain_value(m[1])
                    next
                end
                m = line.match(x0x7_regex)
                if m 
                    updated_title = read_keychain_value(m[1])
                    next
                end
                m = line.match(type_regex)
                if m
                    type = read_keychain_value(m[1])
                    next
                end
            end

            if type == "note"
                note = read_note_from_plist(REXML::Document.new(data_str))
            end
            
            DumpEntry.new(
                keychain,
                class_name,
                type,
                original_title,
                updated_title,
                note
            )
        }

        entries = entries.select {|e|
            if e.type != "note"
                next false
            end
            e.match(regex)
        }.sort

        return entries
    end

    def split_entries(lines)
        return Enumerator.new {|y|
            i = 0
            entry = nil
            while i < lines.length
                line = lines[i]
                i += 1
                m = line.match(keychain_regex)
                if m
                    if entry
                        y << [entry[:keychain], entry[:lines]]
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
            y << [entry[:keychain], entry[:lines]]
        }
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