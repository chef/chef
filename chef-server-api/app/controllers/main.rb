class Main < Application

  provides :html, :json

  def index
    case content_type
    when :json
      display absolute_url(:nodes) => "Manage Nodes",
              absolute_url(:roles) => "Manage Roles",
              absolute_url(:cookbooks) => "Manage Cookbooks",
              absolute_url(:data) => "Manage Data Bags",
              absolute_url(:search) => "Search"
    else
      @webui_url = if Chef::Config[:chef_webui_url]
        Chef::Config[:chef_webui_url]
      elsif request.host =~ /(.*):4000/
        absolute_url(:top, :host => "#{$1}:4040")
      else
        nil
      end
      render
    end
  end

end
