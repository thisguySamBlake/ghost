require 'awesome_print'
require_relative 'lib/parser'
require_relative 'lib/reader'
require_relative 'lib/transform'

test_ghost = "test"

task :test => ["test:parser", "test:transform"]

namespace 'test' do
  task :reader do
    ghost_string = Ghost::Reader.new.read test_ghost
    puts ghost_string
  end

  task :parser do
    parse = Ghost::Parser.new.parse Ghost::Reader.new.read test_ghost
    ap parse
  end

  task :transform do
    game = Ghost::Transform.new.apply Ghost::Parser.new.parse Ghost::Reader.new.read test_ghost
    ap game, raw: true
  end

  task :game do
    game = Ghost::Transform.new.apply Ghost::Parser.new.parse Ghost::Reader.new.read test_ghost
    game.play
  end
end
