# Controller for handling the login, logout process for "users" of our
# little server.  Users have no password.  This is just an example.

require 'openid'

class OpenidRegister < Application

  provides :html, :json

  def index
    @headers['X-XRDS-Location'] = absolute_url(:controller => "server", :action => "idp_xrds")
    @registered_nodes = Chef::FileStore.list("openid_node")
    display @registered_nodes
  end
  
  def show
    begin
       @registered_node = Chef::FileStore.load("openid_node", params[:id])
     rescue RuntimeError => e
       raise NotFound, "Cannot load node registration for #{params[:id]}"
     end
     display @registered_node
  end
  
  def create
    params.has_key?(:id) or raise BadRequest, "You must provide an id to register"
    params.has_key?(:password) or raise BadRequest, "You must provide a password to register"
    if Chef::FileStore.has_key?("openid_node", params[:id])
      raise BadRequest, "You cannot re-register #{params[:id]}!"
    end
    salt = generate_salt
    @registered_node = {
      :id => params[:id],
      :salt => salt,
      :password => encrypt_password(salt, params[:password])
    }
    Chef::FileStore.store(
      "openid_node", 
      params[:id],
      @registered_node
    )
    display @registered_node
  end
  
  def update
    raise BadRequest, "You cannot update your registration -- delete #{params[:id]} and re-register"
  end
  
  def destroy
    unless Chef::FileStore.has_key?("openid_node", params[:id])
      raise BadRequest, "Cannot find the registration for #{params[:id]}"
    end
    Chef::FileStore.delete("openid_node", params[:id])
    display({ :message => "Deleted registration for #{params[:id]}"})
  end

  def submit
    user = params[:username]

    # if we get a user, log them in by putting their username in
    # the session hash.
    unless user.nil?
      session[:username] = user unless user.nil?
      session[:approvals] = []
      session[:notice] = "Your OpenID URL is <b>
        #{url(:controller => "openid_server", :action => "user_page", :username => params[:username])}
        </b><br/><br/>Proceed to step 2 below."
    else
      session[:error] = "Sorry, couldn't log you in. Try again."
    end
    
    redirect url(:openid_login)
  end

  def logout
    # delete the username from the session hash
    session[:username] = nil
    session[:approvals] = nil
    redirect url(:openid_login)
  end

  private
    def generate_salt
      salt = Time.now.to_s
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      1.upto(30) { |i| salt << chars[rand(chars.size-1)] }
      salt
    end
    
    def encrypt_password(salt, password)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
end
