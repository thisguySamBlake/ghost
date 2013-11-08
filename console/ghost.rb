require 'readline'
require 'trollop'
require_relative File.join "..", "test", "game"

opts = Trollop::options do
  opt :debug, "Enable debugging commands"
end

game = test_game
game.debug = opts[:debug]

puts
puts game.start
puts

begin
  while input = Readline.readline("> ", true).downcase
    # Delete history entry if input is all whitespace
    Readline::HISTORY.pop if /^\s*$/ =~ input

    # Delete history entry if input is the same as the previous input
    if Readline::HISTORY.length > 2 and Readline::HISTORY[Readline::HISTORY.length - 2] == input
      Readline::HISTORY.pop
    end

    result = game.execute input

    if result.wait
      puts
      result.wait.times do
        sleep 1 unless game.debug
        print "."
        $stdout.flush
      end
      puts
    end

    puts
    puts result
    puts

    if result.endgame
      exit
    end
  end
rescue Interrupt => e
  exit
end
