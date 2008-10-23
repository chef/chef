#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require "openid"
require 'openid/store/filesystem'

class OpenidConsumer < Application

  provides :html, :json

  def index
    render
  end

  def start
    check_valid_openid_provider(params[:openid_identifier])
    begin
      oidreq = consumer.begin(params[:openid_identifier])
    rescue OpenID::OpenIDError => e
      raise BadRequest, "Discovery failed for #{params[:openid_identifier]}: #{e}"
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
          raise BadRequest, "Verification of #{oidresp.display_identifier} failed: #{oidresp.message}"
        else
          raise BadRequest, "Verification failed: #{oidresp.message}"
        end
      when OpenID::Consumer::SUCCESS
        session[:openid] = oidresp.identity_url
        if oidresp.display_identifier =~ /openid\/server\/node\/(.+)$/
          session[:level] = :node
          session[:node_name] = $1
        else
          session[:level] = :admin
        end
        redirect_back_or_default(absolute_url(:nodes))
        return "Verification of #{oidresp.display_identifier} succeeded."
      when OpenID::Consumer::SETUP_NEEDED
        return "Immediate request failed - Setup Needed"
      when OpenID::Consumer::CANCEL
        return "OpenID transaction cancelled."
      else
    end
    redirect absolute_url(:openid_consumer)
  end
  
  def logout
    session[:openid] = nil    if session.has_key?(:openid)
    session[:level] = nil     if session.has_key?(:level)
    session[:node_name] = nil if session.has_key?(:node_name)
    redirect url(:top)
  end

  private
  
  # Returns true if the openid is at a valid provider, based on whether :openid_providers is 
  # defined.  Raises an exception if it is not an allowed provider.
  def check_valid_openid_provider(openid)
    if Chef::Config[:openid_providers]
      fp = Chef::Config[:openid_providers].detect do |p|
        case openid
        when /^http:\/\/#{p}/, /^#{p}/
          true
        else
          false
        end
      end
      unless fp 
        raise Unauthorized, "Sorry, #{openid} is not an allowed OpenID Provider."
      end
    end
    true
  end

  def consumer
    if @consumer.nil?
      dir = Chef::Config[:openid_cstore_path]
      store = OpenID::Store::Filesystem.new(dir)
      @consumer = OpenID::Consumer.new(session, store)
    end
    return @consumer
  end
end
