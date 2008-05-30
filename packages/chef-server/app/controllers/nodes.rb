class Nodes < Application
  
  provides :html, :json
  
  before :fix_up_node_id
  
  def index
    @node_list = Chef::FileStore.list("node") 
    display @node_list
  end

  def show
    begin
      @node = Chef::FileStore.load("node", params[:id])
    rescue RuntimeError => e
      raise BadRequest, "Cannot load node #{params[:id]}"
    end
    display @node
  end

  def create
    @node = params.has_key?("inflated_object") ? params["inflated_object"] : nil
    if @node
      @status = 202
      Chef::FileStore.store("node", @node.name, @node)
      Chef::Queue.send_msg(:queue, :node_index, @node)
      display @node
    else
      raise BadRequest, "You must provide a Node to create"
    end
  end

  def update
    @node = params.has_key?("inflated_object") ? params["inflated_object"] : nil
    if @node
      @status = 202
      Chef::FileStore.store("node", @node.name, @node)
      Chef::Queue.send_msg(:queue, :node_index, @node)
      display @node
    else
      raise BadRequest, "You must provide a Node to update"
    end
  end

  def destroy
    begin
      @node = Chef::FileStore.load("node", params[:id])
    rescue RuntimeError => e
      raise BadRequest, "Node #{params[:id]} does not exist to destroy!"
    end
    @status = 202
    Chef::FileStore.delete("node", params[:id])
    Chef::Queue.send_msg(:queue, :node_remove, @node)
    display @node
  end
  
  def compile
    # Grab a Chef::Compile object
    compile = Chef::Compile.new()
    compile.load_node(params[:id])
    
    stored_node = Chef::FileStore.load("node", params[:id])
    
    stored_node.each_attribute do |field, value|
      compile.node[field] = value
    end
    stored_node.recipes.each do |r|
      compile.node.recipes << r unless compile.node.recipes.detect { |h| r == h }
    end
    Chef::FileStore.store("node", params[:id], compile.node)
    compile.load_definitions
    compile.load_recipes
    @output = {
      :node => compile.node,
      :collection => compile.collection,
    }
    display @output
  end
  
  def fix_up_node_id
    if params.has_key?(:id)
      params[:id].gsub!(/_/, '.')
    end
  end
  
end
