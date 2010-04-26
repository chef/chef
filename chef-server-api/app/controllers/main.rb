class Main < Application

  before :authenticate_every
  provides :html, :json

  def index
    display(
      { 
        absolute_url(:nodes) => "Manage Nodes",
        absolute_url(:roles) => "Manage Roles",
        absolute_url(:cookbooks) => "Manage Cookbooks",
        absolute_url(:data) => "Manage Data Bags",
        absolute_url(:search) => "Search"
      }
    )
  end
  
end
