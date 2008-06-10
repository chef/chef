class Application < Merb::Controller

  def fix_up_node_id
    if params.has_key?(:id)
      params[:id].gsub!(/_/, '.')
    end
  end
  
  def escape_node_id
    if params.has_key?(:id)
      params[:id].gsub(/_/, '.')
    end
  end
  
  def login_required
    if session[:openid]
      return session[:openid]
    else  
      self.store_location
      throw(:halt, :access_denied)
    end
  end
  
  def authorized_node
    if session[:level] == :admin
      Chef::Log.debug("Authorized as Administrator")
      true
    elsif session[:level] == :node
      Chef::Log.debug("Authorized as node")
      if session[:node_name] == params[:id].gsub(/\./, '_')
        true
      else
        raise(
          Unauthorized,
          "You are not the correct node for this action: #{session[:node_name]} instead of #{params[:id]}"
        )
      end
    else
      Chef::Log.debug("Unauthorized")
      raise Unauthorized, "You are not allowed to take this action."
    end
  end
  
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.uri
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    loc = session[:return_to] || default
    session[:return_to] = nil
    redirect loc
  end
  
  def access_denied
    case content_type
    when :html
      store_location
      redirect url(:openid_consumer)
    else
      raise Unauthorized, "You must authenticate first!"
    end
  end

end