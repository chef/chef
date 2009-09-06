require 'chef/api_client'

class ChefServerApi::Clients < ChefServerApi::Application
  provides :json

  before :authenticate_every
  
  # GET /clients
  def index
    @list = Chef::ApiClient.list(true)
    display(@list.collect { |r| { r.name => absolute_slice_url(:client, :id => r.name) } })
  end

  # GET /clients/:id
  def show
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    @client.couchdb_rev = nil
    @client.public_key = nil
    display @client
  end

  # POST /clients
  def create
    @client = params["inflated_object"]
    exists = true 
    begin
      Chef::Client.load(@client.name)
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false 
    end
    raise Forbidden, "Client already exists" if exists

    @client.save
    
    self.status = 201
    display({ :uri => absolute_slice_url(:client, :id => @client.name)  })
  end

  # PUT /clients/:id
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

