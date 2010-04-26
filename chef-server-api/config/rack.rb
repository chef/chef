# Correctly set a content length.
use Rack::ContentLength

# this is our main merb application
run Merb::Rack::Application.new
