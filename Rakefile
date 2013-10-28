require 'awesome_print'
require 'parslet'
require 'parslet/convenience'
require_relative File.join "lib", "parser"
require_relative File.join "lib", "reader"
require_relative File.join "lib", "transform"

test_ghost = File.join File.dirname(__FILE__), "test", "game"

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
    system "ruby ghost.rb --debug", { chdir: "console" }
  end

  task :server do
    system "ruby server.rb", { chdir: "ajax" }
  end

  task :client do
    if system "middleman build", { chdir: "web" }
      system "ruby server.rb", { chdir: "ajax" }
    end
  end
end
