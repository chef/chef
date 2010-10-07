require 'chef/role'

class Roles < Application
  provides :json

  before :authenticate_every
  before :is_admin, :only => [ :create, :update, :destroy ]
  
  # GET /roles
  def index
    @role_list = Chef::Role.cdb_list(true)
    display(@role_list.inject({}) { |r,role| r[role.name] = absolute_url(:role, role.name); r })
  end

  # GET /roles/:id
  def show
    begin
      @role = Chef::Role.cdb_load(params[:id])
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
      Chef::Role.cdb_load(@role.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false 
    end
    raise Conflict, "Role already exists" if exists

    @role.cdb_save
    
    self.status = 201
    display({ :uri => absolute_url(:role, :id => @role.name)  })
  end

  # PUT /roles/:id
  def update
    begin
      @role = Chef::Role.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end

    @role.update_from!(params["inflated_object"])
    @role.cdb_save
    self.status = 200
    @role.couchdb_rev = nil
    display(@role)
  end

  # DELETE /roles/:id
  def destroy
    begin
      @role = Chef::Role.cdb_load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:id]}"
    end
    @role.cdb_destroy
    display @role
  end

  # GET /roles/:id/environments/:env_id
  def environment
    begin
      @role = Chef::Role.cdb_load(params[:role_id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:role_id]}"
    end
    display("run_list" => @role.env_run_lists[params[:env_id]])
  end
  
  # GET /roles/:id/environments
  def environments
    begin
      @role = Chef::Role.cdb_load(params[:role_id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load role #{params[:role_id]}"
    end
    
    display(@role.env_run_lists.keys.sort)
  end
  

end
