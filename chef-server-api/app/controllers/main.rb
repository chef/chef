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
      @webui_host_with_port = request.host[/(.*):4000/, 1] << ':4040'
      render
    end
  end
  
end
