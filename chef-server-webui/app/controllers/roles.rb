require 'chef/role'

class ChefServerWebui::Roles < ChefServerWebui::Application

  provides :html
  before :login_required 
  
  # GET /roles
  def index
    @role_list = Chef::Role.list(true)
    render
  end

  # GET /roles/:id
  def show
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    render
  end

  # GET /roles/new
  def new
    @available_recipes = get_available_recipes 
    @role = Chef::Role.new
    @current_recipes = @role.recipes
    render
  end

  # GET /roles/:id/edit
  def edit
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    @available_recipes = get_available_recipes 
    @current_recipes = @role.recipes
    render 
  end

  # POST /roles
  def create
    begin
      @role = Chef::Role.new
      @role.name(params[:name])
      @role.recipes(params[:for_role] ? params[:for_role] : [])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @role.save
      redirect(slice_url(:roles), :message => { :notice => "Created Role #{@role.name}" })
    rescue ArgumentError 
      @available_recipes = get_available_recipes 
      @role = Chef::Role.new
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @current_recipes = params[:for_role] ? params[:for_role] : []
      @_message = { :error => $! }
      render :new
    end
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end

    begin
      @role.recipes(params[:for_role])
      @role.description(params[:description]) if params[:description] != ''
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      @role.save
      @_message = { :notice => "Updated Role" }
      render :show
    rescue ArgumentError
      @available_recipes = get_available_recipes 
      @current_recipes = params[:for_role] ? params[:for_role] : []
      @role.default_attributes(JSON.parse(params[:default_attributes])) if params[:default_attributes] != ''
      @role.override_attributes(JSON.parse(params[:override_attributes])) if params[:override_attributes] != ''
      render :edit
    end
  end

  # DELETE /roles/:id
  def destroy
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    @role.destroy
    
    redirect(absolute_slice_url(:roles), :message => { :notice => "Role #{@role.name} deleted successfully." }, :permanent => true)
  end

end
