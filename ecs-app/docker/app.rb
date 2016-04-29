require "sinatra"
require "unicorn"
require 'socket'

class App < Sinatra::Base
  get "/hostname" do
    Socket.gethostname
  end

  get "/foo" do
    "bar"
  end
end
