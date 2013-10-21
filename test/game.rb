require_relative File.join "..", "lib", "parser"
require_relative File.join "..", "lib", "reader"
require_relative File.join "..", "lib", "transform"

def test_game
  ghost_string = Ghost::Reader.new.read File.join(File.dirname(__FILE__), "game")
  Ghost::Transform.new.apply Ghost::Parser.new.parse ghost_string
end
