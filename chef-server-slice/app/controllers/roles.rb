require 'chef/role'

class ChefServerSlice::Roles < ChefServerSlice::Application

  provides :html, :json
  before :login_required 
  
  # GET /roles
  def index
    @role_list = Chef::Role.list(true)
    display(@role_list.collect { |r| absolute_slice_url(:role, r.name) }) 
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

  # GET /roles/:id/delete
  def delete
    
  end

  # POST /roles
  def create
    if params.has_key?("inflated_object")
      @role = params["inflated_object"]
      exists = true 
      begin
        Chef::Role.load(@role.name)
      rescue Net::HTTPServerException
        exists = false 
      end
      raise Forbidden, "Role already exists" if exists

      @role.save
      self.status = 201
      display({ :uri => absolute_slice_url(:role, @role.name) })
    else
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
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end

    if params.has_key?("inflated_object")
      @role.description(params["inflated_object"].description)
      @role.recipes(params["inflated_object"].recipes)
      @role.default_attributes(params["inflated_object"].default_attributes)
      @role.override_attributes(params["inflated_object"].override_attributes)
      @role.save
      self.status = 200
      display(@role)
    else
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
  end

  # DELETE /roles/:id
  def destroy
    begin
      @role = Chef::Role.load(params[:id])
    rescue Net::HTTPServerException => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    @role.destroy
    
    if request.accept == "application/json"
      display @role
    else
      redirect(absolute_slice_url(:roles), :message => { :notice => "Role #{@role.name} deleted successfully." }, :permanent => true)
    end
  end

end
