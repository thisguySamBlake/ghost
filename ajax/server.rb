require 'json'
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
  result = session[:game].start

  response_data = {}
  response_data[:markup] = process_markup result.to_s
  response_data[:seen]   = false
  response_data.to_json
end

get '/execute/*' do |command|
  result = session[:game].execute command

  response_data = {}
  response_data[:markup] = process_markup result.to_s
  response_data[:seen]   = result.seen
  response_data.to_json
end

def process_markup(markup)
  # Parse Markdown after accounting for alternate blockquote syntax
  markdown markup.gsub /^    /, "> "
end
