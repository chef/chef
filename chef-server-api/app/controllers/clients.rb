require 'chef/api_client'

class ChefServerApi::Clients < ChefServerApi::Application
  provides :json

  before :authenticate_every
  before :is_admin, :only => :index
  before :is_correct_node, :only => [ :show, :create, :update, :destroy ]
  
  # GET /clients
  def index
    @list = Chef::ApiClient.list(true)
    display(@list.inject({}) { |result, element| result[element.name] = absolute_slice_url(:client, :id => element.name); result })
  end

  # GET /clients/:id
  def show
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    display({ :name => @client.name, :admin => @client.admin })
  end

  # POST /clients
  def create
    exists = true 
    if params.has_key?(:inflated_object)
      params[:name] ||= params[:inflated_object].name
      params[:admin] ||= params[:inflated_object].admin
    end

    begin
      Chef::ApiClient.load(params[:name])
    rescue Chef::Exceptions::CouchDBNotFound
      exists = false 
    end
    raise Forbidden, "Client already exists" if exists

    @client = Chef::ApiClient.new
    @client.name(params[:name])
    @client.admin(params[:admin]) if params[:admin]
    @client.create_keys
    @client.save
    
    self.status = 201
    headers['Location'] = absolute_slice_url(:client, @client.name)
    display({ :uri => absolute_slice_url(:client, @client.name), :private_key => @client.private_key })
  end

  # PUT /clients/:id
  def update
    if params.has_key?(:inflated_object)
      params[:private_key] ||= params[:inflated_object].private_key
      params[:admin] ||= params[:inflated_object].admin
    end

    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    
    @client.admin(params[:admin]) if params[:admin]

    results = { :name => @client.name, :admin => @client.admin }

    if params[:private_key] == true
      @client.create_keys
      results[:private_key] = @client.private_key
    end

    @client.save

    display(results)
  end

  # DELETE /roles/:id
  def destroy
    begin
      @client = Chef::ApiClient.load(params[:id])
    rescue Chef::Exceptions::CouchDBNotFound => e
      raise NotFound, "Cannot load client #{params[:id]}"
    end
    @client.destroy
    display({ :name => @client.name })
  end

end

