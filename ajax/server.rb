require 'sinatra'
require_relative File.join "..", "test", "game"

use Rack::Session::Pool, :expire_after => 1296000

get %r{^(?!/execute/.*$)} do
  session[:game] = test_game
  session[:game].start
end

get '/execute/*' do |command|
  session[:game].execute command
end
