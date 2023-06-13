#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to generate builtin EmuPad rule binary.
# Also serves as an example of parsing PADMAP rules with regex.

PADMAP = <<PADMAP
# Place your builtin rules below


PADMAP

BUTTONS_COUNT = 10

data = String.new

PADMAP.each_line.with_index do |line,i|
    if line =~ /^(?:\s*(\w+|\*)\s+([0-9A-F]{8})((?:\s+\d+)*))?(?:\s*#.*)?$/
        next unless $1
        appname = $1 # we don't really care about it here
        hwid = $2.to_i 16
        buttons = $3.scan(/\d+/).map(&:to_i)
        maptype = 2 # Always create builtin rules
        buttons << 0 while buttons.size < 10
        if buttons.size > BUTTONS_COUNT
            puts "Warning: too many buttons in line #{i}"
            buttons = buttons.take BUTTONS_COUNT
        end
        [hwid,maptype,*buttons].pack("L<C*", buffer: data)
    else
        puts "Syntax error in line #{i}"
    end
end

File.binwrite("padmap_builtin.dat",data)
