require 'pathname'

require "openid"
require 'openid/store/filesystem'

class OpenidConsumer < Application

  def index
    render
  end

  def start
    begin
      oidreq = consumer.begin(params[:openid_identifier])
    rescue OpenID::OpenIDError => e
      session[:error] = "Discovery failed for #{params[:openid_identifier]}: #{e}"
      return redirect(url(:openid_consumer))
    end
    return_to = absolute_url(:openid_consumer_complete)
    realm = absolute_url(:openid_consumer)
    
    if oidreq.send_redirect?(realm, return_to, params[:immediate])
      return redirect(oidreq.redirect_url(realm, return_to, params[:immediate]))
    else
      @form_text = oidreq.form_markup(realm, return_to, params[:immediate], {'id' => 'openid_form'})
      render 
    end
  end

  def complete
    # FIXME - url_for some action is not necessarily the current URL.
    current_url = absolute_url(:openid_consumer_complete)
    parameters = params.reject{|k,v| k == "controller" || k == "action"}
    oidresp = consumer.complete(parameters, current_url)
    case oidresp.status
    when OpenID::Consumer::FAILURE
      if oidresp.display_identifier
        session[:error] = ("Verification of #{oidresp.display_identifier}"\
                         " failed: #{oidresp.message}")
      else
        session[:error] = "Verification failed: #{oidresp.message}"
      end
    when OpenID::Consumer::SUCCESS
      session[:success] = ("Verification of #{oidresp.display_identifier}"\
                         " succeeded.")
    when OpenID::Consumer::SETUP_NEEDED
      session[:alert] = "Immediate request failed - Setup Needed"
    when OpenID::Consumer::CANCEL
      session[:alert] = "OpenID transaction cancelled."
    else
    end
    redirect url(:openid_consumer)
  end

  private

  def consumer
    if @consumer.nil?
      dir = Pathname.new(Merb.root).join('db').join('cstore')
      store = OpenID::Store::Filesystem.new(dir)
      @consumer = OpenID::Consumer.new(session, store)
    end
    return @consumer
  end
end
