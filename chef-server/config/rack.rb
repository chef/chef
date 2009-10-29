$: << File.join(File.dirname(__FILE__))

# use PathPrefix Middleware if :path_prefix is set in Merb::Config
if prefix = ::Merb::Config[:path_prefix]
  use Merb::Rack::PathPrefix, prefix
end

# comment this out if you are running merb behind a load balancer
# that serves static files
use Merb::Rack::Static, Merb.dir_for(:public)

Merb::Slices.config.each do |slice_module, config|
  slice_module = Object.full_const_get(slice_module.to_s.camel_case) if slice_module.class.in?(String, Symbol)
  slice_module.send("public_components").each do |component|
    slice_static_dir = slice_module.send("dir_for", :public)
    use Merb::Rack::Static, slice_static_dir
  end
end

# this is our main merb application
run Merb::Rack::Application.new
