task :test do
  require_relative 'lib/parser'
  require 'pp'
  pp GhostParser.new.parse(File.open("test/test.ghost").read)
end
