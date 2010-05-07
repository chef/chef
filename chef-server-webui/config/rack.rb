use Rack::ContentLength
use Merb::Rack::Static, Merb.dir_for(:public)

# this is our main merb application
run Merb::Rack::Application.new
