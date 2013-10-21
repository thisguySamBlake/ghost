require 'readline'
require_relative File.join "..", "lib", "parser"
require_relative File.join "..", "lib", "reader"
require_relative File.join "..", "lib", "transform"

ghost_string = Ghost::Reader.new.read File.join File.dirname(__FILE__), "..", "test"
game = Ghost::Transform.new.apply Ghost::Parser.new.parse ghost_string

puts
puts game.start
puts

begin
  while input = Readline.readline("> ", true).downcase
    puts
    if input == "quit"
      exit
    else
      puts game.execute input
    end
    puts
  end
rescue Interrupt => e
  puts "quit"
  puts
  exit
end
