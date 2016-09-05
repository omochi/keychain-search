def exec(command)
    system(command)
    st = $?
    if ! st.success?
        raise "exec failed: status=#{st}, command=#{command}"
    end
end

def exec_capture(command)
    capture = `#{command}`
    st = $?
    if ! st.success?
        raise "exec failed: status=#{st}, command=#{command}"
    end
    return capture
end

def hex_to_string(hex)
    i = 0
    bytes = []
    while i + 1 < hex.length
        char2 = hex[(i)..(i+1)]
        i += 2
        byte = char2.hex
        bytes << byte
    end
    return bytes.pack("C*").force_encoding("UTF-8")
end

def read_keychain_value(string)
    regex = /^(?:0x([0-9A-F]*)|"([^"]*)")/
    m = string.match(regex)
    if ! m
        return nil
    end
    if m[1]
        return hex_to_string(m[1])
    end
    return m[2]
end

def compare_nillables(a, b)
    if a
        if b
            return yield(a, b)
        else
            return +1
        end
    else
        if b
            return -1
        else
            return 0
        end
    end
    
end