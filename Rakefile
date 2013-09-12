require 'awesome_print'
require_relative 'lib/parser'
require_relative 'lib/transform'

test_ghost = File.open("test/test.ghost").read

task :test => ["test:parser", "test:transform"]

namespace 'test' do
  task :parser do
    parse = GhostParser.new.parse test_ghost
    ap parse
  end

  task :transform do
    game = GhostTransform.new.apply GhostParser.new.parse test_ghost
    ap game, raw: true
  end

  task :game do
    game = GhostTransform.new.apply GhostParser.new.parse test_ghost
    game.play
  end
end
