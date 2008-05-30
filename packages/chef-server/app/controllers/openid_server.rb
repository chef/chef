require 'pathname'

# load the openid library, first trying rubygems
#begin
#  require "rubygems"
#  require_gem "ruby-openid", ">= 1.0"
#rescue LoadError
require "openid"
require "openid/consumer/discovery"
require 'openid/store/filesystem'
#end

class OpenidServer < Application

  include Merb::OpenidServerHelper
  include OpenID::Server
  
  layout nil

  def index
    
    oidreq = server.decode_request(params)
    
    # no openid.mode was given
    unless oidreq
      return "This is the Chef OpenID server endpoint."
    end

    oidresp = nil

    if oidreq.kind_of?(CheckIDRequest)

      identity = oidreq.identity

      if oidreq.id_select
        if oidreq.immediate
          oidresp = oidreq.answer(false)
        elsif session[:username].nil?
          # The user hasn't logged in.
          return show_decision_page(oidreq)
        else
          # Else, set the identity to the one the user is using.
          identity = url_for_user
        end
      end

      if oidresp
        nil
      elsif self.is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)
      elsif oidreq.immediate
        server_url = url :openid_server
        oidresp = oidreq.answer(false, server_url)
      else
        return show_decision_page(oidreq)
      end

    else
      oidresp = server.handle_request(oidreq)
    end

    self.render_response(oidresp)
  end

  def show_decision_page(oidreq, message="Do you trust this site with your identity?")
    session[:last_oidreq] = oidreq
    @oidreq = oidreq

    if message
      session[:notice] = message
    end

    render :template => 'openid_server/decide'
  end

  def user_page
    # Yadis content-negotiation: we want to return the xrds if asked for.
    accept = request.env['HTTP_ACCEPT']

    # This is not technically correct, and should eventually be updated
    # to do real Accept header parsing and logic.  Though I expect it will work
    # 99% of the time.
    if accept and accept.include?('application/xrds+xml')
      return user_xrds
    end

    # content negotiation failed, so just render the user page
    xrds_url = url(:openid_user_xrds, :username => params[:username])
    identity_page = <<EOS
<html><head>
<meta http-equiv="X-XRDS-Location" content="#{xrds_url}" />
<link rel="openid.server" href="#{absolute_url :openid_user, :username}" />
</head><body><p>OpenID identity page for #{params[:username]}</p>
</body></html>
EOS

    # Also add the Yadis location header, so that they don't have
    # to parse the html unless absolutely necessary.
    @headers['X-XRDS-Location'] = xrds_url
    render identity_page
  end

  def user_xrds
    types = [
             OpenID::OPENID_2_0_TYPE,
             OpenID::OPENID_1_0_TYPE,
             OpenID::SREG_URI,
            ]

    render_xrds(types)
  end

  def idp_xrds
    types = [
             OpenID::OPENID_IDP_2_0_TYPE,
            ]

    render_xrds(types)
  end

  def decision
    oidreq = session[:last_oidreq]
    session[:last_oidreq] = nil

    if params[:yes].nil?
      redirect oidreq.cancel_url
      return
    else
      id_to_send = params[:id_to_send]

      identity = oidreq.identity
      if oidreq.id_select
        if id_to_send and id_to_send != ""
          session[:username] = id_to_send
          session[:approvals] = []
          identity = url_for_user
        else
          msg = "You must enter a username to in order to send " +
            "an identifier to the Relying Party."
          return show_decision_page(oidreq, msg)
        end
      end

      if session[:approvals]
        session[:approvals] << oidreq.trust_root
      else
        session[:approvals] = [oidreq.trust_root]
      end
      oidresp = oidreq.answer(true, nil, identity)
      return self.render_response(oidresp)
    end
  end

  protected

  def server
    if @server.nil?
      server_url = absolute_url(:openid_server)
      dir = Pathname.new(Merb.root).join('db').join('openid-store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store, server_url)
    end
    return @server
  end

  def approved(trust_root)
    return false if session[:approvals].nil?
    return session[:approvals].member?(trust_root)
  end

  def is_authorized(identity_url, trust_root)
    return (session[:username] and (identity_url == url_for_user) and self.approved(trust_root))
  end

  def render_xrds(types)
    type_str = ""

    types.each { |uri|
      type_str += "<Type>#{uri}</Type>\n      "
    }

    yadis = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      #{type_str}
      <URI>#{absolute_url(:openid_server)}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
EOS

    @headers['content-type'] = 'application/xrds+xml'
    render yadis
  end

  def render_response(oidresp)
    if oidresp.needs_signing
      signed_response = server.signatory.sign(oidresp)
    end
    web_response = server.encode_response(oidresp)

    case web_response.code
    when HTTP_OK
      @status = 200
      render web_response.body
    when HTTP_REDIRECT
      redirect web_response.headers['location']
    else
      @status = 400
      render web_response.body
    end
  end


end
