require 'kramdown'
require 'sinatra'
require_relative File.join "..", "test", "game"

# Maintain game sessions for two weeks
use Rack::Session::Pool, :expire_after => 1296000

# Serve static files from Middleman output
set :public_folder, File.join(File.dirname(__FILE__), "..", "web", "build")

get '/' do
  send_file File.join settings.public_folder, "index.html"
end

get '/start/' do
  session[:game] = test_game
  process_markup session[:game].start
end

get '/execute/*' do |command|
  process_markup session[:game].execute command
end

def process_markup(markup)
  # Parse Markdown after accounting for alternate blockquote syntax
  markdown markup.gsub /^    /, "> "
end
