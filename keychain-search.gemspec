Gem::Specification.new do |s|
    s.name = "keychain-search"
    s.version = "1.0.0"
    s.licenses = ["MIT"]
    s.summary = "Search secret notes in keychain of Mac OS X"
    s.description = "Search secret notes in keychain of Mac OS X"
    s.authors = ["omochimetaru"]
    s.email = "omochi.metaru@gmail.com"
    s.files = Dir["lib/*.rb"] + Dir["bin/*"]
    s.homepage = "https://github.com/omochi/keychain-search"
    s.bindir = "bin"
    s.executables = ["kcs"]
end
