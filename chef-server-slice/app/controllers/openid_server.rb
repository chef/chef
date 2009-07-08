#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'pathname'

# load the openid library, first trying rubygems
#begin
#  require "rubygems"
#  require_gem "ruby-openid", ">= 1.0"
#rescue LoadError
require "openid"
require "openid/consumer/discovery"
require 'json'
require 'chef' / 'openid_registration'
#end

class ChefServerSlice::OpenidServer < ChefServerSlice::Application

  provides :html, :json

  include Merb::ChefServerSlice::OpenidServerHelper
  include OpenID::Server
  
  layout nil
  
  before :fix_up_node_id
  after :dump_cookies_and_session

  def index
        
    oidreq = server.decode_request(params.reject{|k,v| k == "controller" || k == "action"})
    
    # no openid.mode was given
    unless oidreq
      return "This is the Chef OpenID server endpoint."
    end

    oidresp = nil

    if oidreq.kind_of?(CheckIDRequest)
      identity = oidreq.identity

      if oidresp
        nil
      elsif self.is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)
      elsif oidreq.immediate
        server_url = slice_url :openid_server
        oidresp = oidreq.answer(false, server_url)
      else
        if content_type == :json
          session[:last_oidreq] = oidreq
          response = { :action => slice_url(:openid_server_decision) }
          return response.to_json
        else
          return show_decision_page(oidreq)
        end
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

  def node_page
    unless Chef::OpenIDRegistration.has_key?(params[:id])
      raise NotFound, "Cannot find registration for #{params[:id]}"
    end
    
    # Yadis content-negotiation: we want to return the xrds if asked for.
    accept = request.env['HTTP_ACCEPT']

    # This is not technically correct, and should eventually be updated
    # to do real Accept header parsing and logic.  Though I expect it will work
    # 99% of the time.
    if accept and accept.include?('application/xrds+xml')
      return node_xrds
    end

    # content negotiation failed, so just render the user page
    xrds_url = absolute_slice_url(:openid_node_xrds, :id => params[:id])
    identity_page = <<EOS
<html><head>
<meta http-equiv="X-XRDS-Location" content="#{xrds_url}" />
<link rel="openid.server" href="#{absolute_slice_url(:openid_node, :id => params[:id])}" />
</head><body><p>OpenID identity page for registration #{params[:id]}</p>
</body></html>
EOS

    # Also add the Yadis location header, so that they don't have
    # to parse the html unless absolutely necessary.
    @headers['X-XRDS-Location'] = xrds_url
    render identity_page
  end

  def node_xrds
    types = [
             OpenID::OPENID_2_0_TYPE,
             OpenID::OPENID_1_0_TYPE
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

    if params.has_key?(:cancel)
      Chef::Log.info("Cancelling OpenID Authentication")
      return(redirect(oidreq.cancel_url))
    else      
      identity = oidreq.identity
      identity =~ /node\/(.+)$/
      openid_node = Chef::OpenIDRegistration.load($1)
      unless openid_node.validated
        raise Unauthorized, "This nodes registration has not been validated"
      end
      if openid_node.password == encrypt_password(openid_node.salt, params[:password])     
        if session[:approvals] and !session[:approvals].include?(oidreq.trust_root)
          session[:approvals] << oidreq.trust_root 
        else
          session[:approvals] = [oidreq.trust_root]
        end
        oidresp = oidreq.answer(true, nil, identity)
        return self.render_response(oidresp)
      else
        raise Unauthorized, "Invalid credentials"
      end
    end
  end

  protected

  def encrypt_password(salt, password)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def server
    if @server.nil?
      server_url = absolute_slice_url(:openid_server)
      if Chef::Config[:openid_store_couchdb]
        require 'openid-store-couchdb'
        store = OpenID::Store::CouchDB.new(Chef::Config[:couchdb_url])
      else
        require 'openid/store/filesystem'
        dir = Chef::Config[:openid_store_path]
        store = OpenID::Store::Filesystem.new(dir)
      end
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
      <URI>#{absolute_slice_url(:openid_server)}</URI>
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

  def dump_cookies_and_session
    unless session.empty? or request.cookies.empty?
      cookie_size = request.cookies.inject(0) {|sum,c| sum + c[1].length }
      c, s = request.cookies.inspect, session.inspect
      Chef::Log.debug("cookie dump (size: #{cookie_size}): #{c}")
      Chef::Log.debug("session dump #{s}")
    end
  end

end
