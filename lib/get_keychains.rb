class GetKeychains
    def run
        cmd = [
            "security",
            "list-keychains"
        ].shelljoin
        output = exec_capture(cmd)
        lines = output.split("\n")
        paths = lines.map {|x|
            m = x.match(/^\s*"([^"]*)"$/)
            m[1]
        }
        return paths
    end
end