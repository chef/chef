require 'chef/role'

class ChefServerApi::Roles < ChefServerApi::Application
  provides :json

  before :authenticate_every
  before :is_admin, :only => [ :create, :update, :destroy ]
  
  # GET /roles
  def index
    @role_list = Chef::Role.cdb_list(true)
    display(@role_list.inject({}) { |r,role| r[role.name] = absolute_slice_url(:role, role.name); r })
  end

  # GET /roles/:id
  def show
    begin
      @role = Chef::Role.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    @role.couchdb_rev = nil
    display @role
  end

  # POST /roles
  def create
    @role = params["inflated_object"]
    exists = true 
    begin
      Chef::Role.load(@role.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false 
    end
    raise Forbidden, "Role already exists" if exists

    @role.save
    
    self.status = 201
    display({ :uri => absolute_slice_url(:role, :id => @role.name)  })
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end

    @role.description(params["inflated_object"].description)
    @role.recipes(params["inflated_object"].recipes)
    @role.default_attributes(params["inflated_object"].default_attributes)
    @role.override_attributes(params["inflated_object"].override_attributes)
    @role.save
    self.status = 200
    @role.couchdb_rev = nil
    display(@role)
  end

  # DELETE /roles/:id
  def destroy
    begin
      @role = Chef::Role.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    @role.destroy
    display @role
  end

end
