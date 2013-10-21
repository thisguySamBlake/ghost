require 'readline'
require_relative File.join "..", "test", "game"

game = test_game

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
