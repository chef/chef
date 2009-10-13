class ChefServerApi::Main < ChefServerApi::Application

  before :authenticate_every
  provides :html, :json

  def index
    display(
      { 
        absolute_slice_url(:nodes) => "Manage Nodes",
        absolute_slice_url(:roles) => "Manage Roles",
        absolute_slice_url(:cookbooks) => "Manage Cookbooks",
        absolute_slice_url(:data) => "Manage Data Bags",
        absolute_slice_url(:search) => "Search"
      }
    )
  end
  
end
