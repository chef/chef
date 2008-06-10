class Nodes < Application
  
  provides :html, :json
  
  before :fix_up_node_id
  before :login_required,  :only => [ :create, :update, :destroy ]
  before :authorized_node, :only => [ :update, :destroy ]
  
  def index
    @node_list = Chef::Node.list 
    display @node_list
  end

  def show
    begin
      @node = Chef::Node.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load node #{params[:id]}"
    end
    display @node
  end

  def create
    @node = params.has_key?("inflated_object") ? params["inflated_object"] : nil    
    if @node
      @status = 202
      @node.save
      display @node
    else
      raise BadRequest, "You must provide a Node to create"
    end
  end

  def update
    @node = params.has_key?("inflated_object") ? params["inflated_object"] : nil
    if @node
      @status = 202
      @node.save
      display @node
    else
      raise NotFound, "You must provide a Node to update"
    end
  end

  def destroy
    begin
      @node = Chef::Node.load(params[:id])
    rescue RuntimeError => e
      raise BadRequest, "Node #{params[:id]} does not exist to destroy!"
    end
    @status = 202
    @node.destroy
    if content_type == :html
      redirect url(:nodes)
    else
      display @node
    end
  end
  
  def compile
    # Grab a Chef::Compile object
    compile = Chef::Compile.new()
    compile.load_node(params[:id])
    compile.node.save
    compile.load_definitions
    compile.load_recipes
    @output = {
      :node => compile.node,
      :collection => compile.collection,
    }
    display @output
  end
  
end
