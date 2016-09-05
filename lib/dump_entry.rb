class DumpEntry
    include Comparable

    def initialize(
        keychain,
        class_name,
        original_title,
        updated_title,
        note
    )
        @keychain = keychain
        @class_name = class_name
        @original_title = original_title
        @updated_title = updated_title
        @note = note
    end

    attr_reader :keychain
    attr_reader :class_name
    
    def title
        return updated_title || original_title
    end

    attr_reader :original_title
    attr_reader :updated_title
    attr_reader :note

    def match(regex)
        if title && title.match(regex)
            return true
        end
        if note && note.match(regex)
            return true
        end
        return false
    end

    def <=>(other)
        compare_nillables(keychain, other.keychain) {|k, ok|
            if k != ok
                next k <=> ok
            end
            compare_nillables(title, other.title) {|t, ot|
                t <=> ot
            }
        }
    end
end
