#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require File.expand_path(File.join(File.dirname(__FILE__), "story_helper"))

steps_for(:chef_client) do
  # Given the node 'latte'
  Given("the node '$node'") do |node|
    @client = Chef::Client.new
    @client.build_node(node)
  end
  
  # Given it has not registered before
  Given("it has not registered before") do
    Chef::FileStore.load("registration", @client.safe_name)
  end

  # When it runs the chef-client
  
  # Then it should register with the Chef Server
  
  # Then CouchDB should have a 'openid_registration_latte' document
  
  # Then the registration validation should be 'false'
  
end

with_steps_for(:chef_client) do
  create_couchdb_database
  run File.join(File.dirname(__FILE__), "chef-client")
end