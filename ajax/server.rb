require 'fileutils'
require 'json'
require 'kramdown'
require 'sinatra'
require_relative File.join "..", "test", "game"

# Maintain game sessions for two weeks
use Rack::Session::Pool, :expire_after => 1296000

# Serve static files from Middleman output
set :public_folder, File.join(File.dirname(__FILE__), "..", "web", "build")

# Parse game object
marshaled_game = Marshal.dump test_game

get '/' do
  send_file File.join settings.public_folder, "index.html"
end

get '/start/' do
  session[:game] = Marshal.load marshaled_game
  result = session[:game].start
  write_to_ghost_log result

  response_data = {}
  response_data[:markup]  = process_markup result.to_s
  response_data[:seen]    = false
  response_data[:wait]    = nil
  response_data[:endgame] = false
  response_data.to_json
end

get '/execute/*' do |command|
  write_to_ghost_log "\n> " + command
  result = session[:game].execute command
  write_to_ghost_log "\n" + result

  response_data = {}
  response_data[:markup]  = process_markup result.to_s
  response_data[:seen]    = result.seen
  response_data[:wait]    = result.wait
  response_data[:endgame] = result.endgame
  response_data.to_json
end

def write_to_ghost_log(data)
  if settings.test?
    log_dir = "logs"

    unless session.has_key? :log
      session[:log] = File.join log_dir, Time.now.strftime("%Y%m%d-%H%M%S") + ".ghost_log"
    end

    unless File.exists? session[:log]
      Dir.mkdir log_dir unless Dir.exist? log_dir
      FileUtils.touch session[:log]
    end

    File.open(session[:log], 'a') { |log| log.write data + "\n" }
  end
end

def process_markup(markup)
  # Parse Markdown after accounting for alternate blockquote syntax
  markdown markup.gsub /^    /, "> "
end
