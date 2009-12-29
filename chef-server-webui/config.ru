require 'rubygems'
require 'merb-core'

Dir.chdir(::File.dirname(__FILE__))

Merb::Config.setup(:merb_root   => ::File.expand_path(::File.dirname(__FILE__)), 
                   :environment => ENV['RACK_ENV'] || "development", 
                   :fork_for_class_load => false,
                   :init_file => ::File.dirname(__FILE__) / "config/init.rb")
Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]

# Uncomment if your app is mounted at a suburi
#if prefix = ::Merb::Config[:path_prefix]
#  use Merb::Rack::PathPrefix, prefix
#end

# comment this out if you are running merb behind a load balancer
# that serves static files
# use Merb::Rack::Static, Merb.dir_for(:public)
use Merb::Rack::Static, Merb.root+"/public"

require 'merb-slices'
slice_name = "chef-server-webui"

if ::File.exists?(slice_file = ::File.join(Merb.root, 'lib', "#{slice_name}.rb"))
  Merb::BootLoader.before_app_loads do
    $SLICE_MODULE = Merb::Slices.filename2module(slice_file)
    require slice_file
  end
  Merb::BootLoader.after_app_loads do
    # See Merb::Slices::ModuleMixin - $SLICE_MODULE is used as a flag
    Merb::Router.prepare do 
      slice($SLICE_MODULE)
      slice_id = slice_name.gsub('-', '_').to_sym
      slice_routes = Merb::Slices.named_routes[slice_id] || {}
    
      # Setup a / root path matching route - try several defaults
      route = slice_routes[:home] || slice_routes[:index]
      if route
        params = route.params.inject({}) do |hsh,(k,v)|
          hsh[k] = v.gsub("\"", '') if k == :controller || k == :action
          hsh
        end
        match('/').to(params)
      else
        match('/').to(:controller => 'merb_slices', :action => 'index')
      end
    end
  end
else
  puts "No slice found (expected: #{slice_name})"
  exit
end

class ::MerbSlices < Merb::Controller
  
  def index
    html = "<h1>#{slice.name}</h1><p>#{slice.description}</p>"  
    html << "<h2>Routes</h2><ul>"
    sorted_names = slice.named_routes.keys.map { |k| [k.to_s, k] }.sort_by { |pair| pair.first }
    sorted_names.each do |_, name|
      if name != :default && (route = slice.named_routes[name])
        if name == :index
          html << %Q[<li><a href="#{url(route.name)}" title="visit #{name}">#{name}: #{route.inspect}</a></li>]
        else
          html << %Q[<li>#{name}: #{route.inspect}</li>]
        end
      end
    end
    html << "</ul>"
    html
  end
  
  private
  
  def slice
    @slice ||= Merb::Slices.slices.first
  end
  
end

Merb::BootLoader.run
run Merb::Rack::Application.new
