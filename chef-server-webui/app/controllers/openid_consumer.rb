#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
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
require 'openid'
require (Chef::Config[:openid_cstore_couchdb] ?   'openid-store-couchdb' : 'openid/store/filesystem')

class OpenidConsumer < Application

  provides :html

  def index
    if request.xhr?
      render :layout => false
    else
      render :layout => 'login'
    end
  end

  def start
    oid = params[:openid_identifier]
    begin
      oidreq = consumer.begin(oid)
    rescue OpenID::OpenIDError => e
      raise BadRequest, "Discovery failed for #{oid}: #{e}"
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

  def login
    if session[:user] 
      redirect(url(:nodes), :message => { :warning => "You've already logged in with user #{session[:user]}"  })
    else
      oid = params[:openid_identifier]
      raise(Unauthorized, "Sorry, #{oid} is not an authorized OpenID.") unless is_authorized_openid_identifier?(oid, Chef::Config[:authorized_openid_identifiers])
      raise(Unauthorized, "Sorry, #{oid} is not an authorized OpenID Provider.") unless is_authorized_openid_provider?(oid, Chef::Config[:authorized_openid_providers])
      start
    end
  end

  def complete
    # FIXME - url_for some action is not necessarily the current URL.
    current_url = absolute_url(:openid_consumer_complete)
    parameters = params.reject{|k,v| k == "controller" || k == "action"}
    oidresp = consumer.complete(parameters, current_url)
    case oidresp.status
      when OpenID::Consumer::FAILURE
        raise BadRequest, "Verification failed: #{oidresp.message}" + (oidresp.display_identifier ? " for identifier '#{oidresp.display_identifier}'" : "")
      when OpenID::Consumer::SUCCESS
        #session[:openid] = oidresp.identity_url
        # The "if" condition no longer seems need to/can be reached, so I took it out. [nuo] 
        #
        # if oidresp.display_identifier =~ /openid\/server\/node\/(.+)$/
        #   reg_name = $1
        #   reg = Chef::OpenIDRegistration.load(reg_name)
        #   Chef::Log.error("#{reg_name} is an admin #{reg.admin}")
        #   session[:level] = reg.admin ? :admin : :node
        #   session[:node_name] = $1
        #else
        users = Chef::WebUIUser.list
        #TODO: This is expensive. Should think of a better way [nuo]
        # Go through each user object and check if the current OpenID associates with the user
        users.each do |u, url|
          user = Chef::WebUIUser.load(u)
          if user.openid == oidresp.identity_url
            session[:user] = user.name
            if user.admin
              session[:level] = :admin
            else
              session[:level] = :user
            end
            break
          end
        end        
        if session[:user].nil?
          redirect(url(:openid_consumer),  :message => { :error => "No user is associated with this OpenID." })
          return "No user is associated with this OpenID."
        end 
        #end
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
    cleanup_session
    redirect url(:top)
  end

  private
  def is_authorized_openid_provider?(openid, authorized_providers)
    Chef::Log.debug("Checking for valid openid provider: openid: #{openid}, authorized providers: #{authorized_providers}")
    if authorized_providers and openid
      if authorized_providers.length > 0
        authorized_providers.detect { |p| Chef::Log.debug("Openid: #{openid} (#{openid.class}), p: #{p} (#{p.class})"); openid.match(p) }
      else
        true
      end
    else
      true
    end
  end
   
  def is_authorized_openid_identifier?(openid, authorized_identifiers)
    Chef::Log.debug("Checking for valid openid identifier: openid: #{openid}, authorized openids: #{authorized_identifiers}")
    if authorized_identifiers and openid
      if authorized_identifiers.length > 0 
        authorized_identifiers.detect { |p| Chef::Log.debug("Openid: #{openid} (#{openid.class}), p: #{p} (#{p.class})"); openid == p } 
      else
        true
      end
    else
      true
    end
  end

  def consumer
    @consumer ||= OpenID::Consumer.new(session,
                                       if Chef::Config[:openid_cstore_couchdb]
                                         OpenID::Store::CouchDB.new(Chef::Config[:couchdb_url])
                                       else
                                         OpenID::Store::Filesystem.new(Chef::Config[:openid_cstore_path])
                                       end)
  end

end
