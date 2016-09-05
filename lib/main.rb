#!/usr/bin/env ruby

require "shellwords"
require "rexml/document"
require_relative "get_keychains"
require_relative "dump_keychain"
require_relative "dump_entry"
require_relative "util"

class App
    def usage
        puts "kcs [keychain] [regex]"
    end
    def main
        if ARGV.length < 2
            usage
            return false
        end

        keychain_key = ARGV[0].downcase
        search_regex = Regexp.new(ARGV[1], Regexp::IGNORECASE | Regexp::MULTILINE)

        keychains = GetKeychains.new.run
        selected_keychain = keychains.select {|x|
            x.downcase.include? keychain_key
        }[0]

        if ! selected_keychain
            puts "no keychain was matched: key=#{keychain_key}"
            puts "keychains"
            for keychain in keychains
                puts "  #{keychain}"
            end
            return false
        end

        entries = DumpKeychain.new.run(selected_keychain, search_regex)
        
        for x in entries
            puts "===="
            puts "keychain: #{x.keychain}"
            puts "title: #{x.title}"
            puts "--"
            puts x.note
        end

        return true
    end
end

exit(App.new.main)
