# Controller for handling the login, logout process for "users" of our
# little server.  Users have no password.  This is just an example.

require 'openid'

class OpenidLogin < Application

  provides :html, :json

  def index
    @headers['X-XRDS-Location'] = url(:controller => "server",
                                                  :action => "idp_xrds",
                                                  :only_path => false)
    display({ })
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
    
    redirect url(:controller => "openid_login")
  end

  def logout
    # delete the username from the session hash
    session[:username] = nil
    session[:approvals] = nil
    redirect url(:controller => "openid_login")
  end

end
