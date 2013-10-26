require 'readline'
require_relative File.join "..", "test", "game"

game = test_game

puts
puts game.start
puts

begin
  while input = Readline.readline("> ", true).downcase
    puts
    result = game.execute input
    puts result
    puts
    if result.endgame
      exit
    end
  end
rescue Interrupt => e
  exit
end
