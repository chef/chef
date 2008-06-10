# Controller for handling the login, logout process for "users" of our
# little server.  Users have no password.  This is just an example.

require 'openid'

class OpenidRegister < Application

  provides :html, :json
  
  before :fix_up_node_id

  def index
    @headers['X-XRDS-Location'] = absolute_url(:controller => "openid_server", :action => "idp_xrds")
    @registered_nodes = Chef::OpenIDRegistration.list(true)
    Chef::Log.debug(@registered_nodes.inspect)
    display @registered_nodes
  end
  
  def show
    begin
      @registered_node = Chef::OpenIDRegistration.load(params[:id])
    rescue Net::HTTPServerException => e
      if e.message =~ /^404/
        raise NotFound, "Cannot load node registration for #{params[:id]}"
      else
        raise e
      end
    end
     Merb.logger.debug(@registered_node.inspect)
     display @registered_node
  end
  
  def create
    params.has_key?(:id) or raise BadRequest, "You must provide an id to register"
    params.has_key?(:password) or raise BadRequest, "You must provide a password to register"
    if Chef::OpenIDRegistration.has_key?(params[:id])
      raise BadRequest, "You cannot re-register #{params[:id]}!"
    end
    @registered_node = Chef::OpenIDRegistration.new
    @registered_node.name = params[:id]
    @registered_node.set_password(params[:password])
    @registered_node.save
    display @registered_node
  end
  
  def update
    raise BadRequest, "You cannot update your registration -- delete #{params[:id]} and re-register"
  end
  
  def destroy
    begin
      r = Chef::OpenIDRegistration.load(params[:id])
    rescue Exception => e
      raise BadRequest, "Cannot find the registration for #{params[:id]}"
    end
    r.destroy
    if content_type == :html
      redirect url(:registrations)
    else
      display({ :message => "Deleted registration for #{params[:id]}"})
    end
  end
  
  def validate
    begin
      r = Chef::OpenIDRegistration.load(params[:id])
    rescue Exception => e
      raise BadRequest, "Cannot find the registration for #{params[:id]}"
    end
    r.validated = r.validated ? false : true
    r.save
    redirect url(:registrations)
  end
end
