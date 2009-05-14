require 'chef/role'

class ChefServerSlice::Roles < ChefServerSlice::Application

  provides :html, :json
  before :login_required 
  
  # GET /roles
  def index
    @role_list = Chef::Role.list(true)
    display @role_list
  end

  # GET /roles/:id
  def show
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    display @role
  end

  # GET /roles/new
  def new
    cl = Chef::CookbookLoader.new
    @available_recipes = cl.sort{ |a,b| a.name.to_s <=> b.name.to_s }
    @current_recipes = Array.new
    render
  end

  # GET /roles/:id/edit
  def edit
    render
  end

  # GET /roles/:id/delete
  def delete
    render
  end

  # POST /roles
  def create
    if params.has_key?("inflated_object")
      @role = params["inflated_object"]
      @role.save
      self.status = 201
      display({ :uri => slice_url(:role, @role.name) })
    else
      @role = Chef::Role.new
      @role.name(params[:name])
      @role.recipes(params[:for_role])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @role.save
      redirect(slice_url(:roles), :message => { :notice => "Created Role #{@role.name}" })
    end
  end

  # PUT /roles/:id
  def update
    render
  end

  # DELETE /roles/:id
  def destroy
    render
  end

end
