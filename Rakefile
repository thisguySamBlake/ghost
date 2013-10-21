require 'awesome_print'
require 'parslet'
require 'parslet/convenience'
require_relative File.join "lib", "parser"
require_relative File.join "lib", "reader"
require_relative File.join "lib", "transform"

test_ghost = "test"

task :test => ["test:parser", "test:transform"]

namespace 'test' do
  task :reader do
    ghost_string = Ghost::Reader.new.read test_ghost
    puts ghost_string
  end

  task :parser do
    parse = Ghost::Parser.new.parse_with_debug Ghost::Reader.new.read test_ghost
    ap parse
  end

  task :transform do
    game = Ghost::Transform.new.apply Ghost::Parser.new.parse Ghost::Reader.new.read test_ghost
    ap game, raw: true
  end

  task :console do
    system "ruby ghost.rb", { chdir: "console" }
  end
end
