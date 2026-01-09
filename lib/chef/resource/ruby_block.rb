#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../resource"
require_relative "../provider/ruby_block"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class RubyBlock < Chef::Resource

      provides :ruby_block, target_mode: true
      target_mode support: :full,
        description: "Ruby code will be run locally and not on the target node. Use the **ruby** resource for this."

      description "Use the **ruby_block** resource to execute Ruby code during a #{ChefUtils::Dist::Infra::PRODUCT} run. Ruby code in the `ruby_block` resource is evaluated with other resources during convergence, whereas Ruby code outside of a `ruby_block` resource is evaluated before other resources, as the recipe is compiled."
      examples <<~'DOC'
        **Reload Chef Infra Client configuration data**

        ```ruby
        ruby_block 'reload_client_config' do
          block do
            Chef::Config.from_file('/etc/chef/client.rb')
          end
          action :run
        end
        ```

        **Run a block on a particular platform**

        The following example shows how an if statement can be used with the `windows?` method in the Chef Infra Language to run code specific to Microsoft Windows. The code is defined using the ruby_block resource:

        ```ruby
        if windows?
          ruby_block 'copy libmysql.dll into ruby path' do
            block do
              require 'fileutils'
              FileUtils.cp "#{node['mysql']['client']['lib_dir']}\\libmysql.dll",
                node['mysql']['client']['ruby_dir']
            end
            not_if { ::File.exist?("#{node['mysql']['client']['ruby_dir']}\\libmysql.dll") }
          end
        end
        ```

        **Stash a file in a data bag**

        The following example shows how to use the ruby_block resource to stash a BitTorrent file in a data bag so that it can be distributed to nodes in the organization.

        ```ruby
        ruby_block 'share the torrent file' do
          block do
            f = File.open(node['bittorrent']['torrent'],'rb')
            #read the .torrent file and base64 encode it
            enc = Base64.encode64(f.read)
            data = {
              'id'=>bittorrent_item_id(node['bittorrent']['file']),
              'seed'=>node.ipaddress,
              'torrent'=>enc
            }
            item = Chef::DataBagItem.new
            item.data_bag('bittorrent')
            item.raw_data = data
            item.save
          end
          action :nothing
          subscribes :create, "bittorrent_torrent[#{node['bittorrent']['torrent']}]", :immediately
        end
        ```

        **Update the /etc/hosts file**

        The following example shows how the ruby_block resource can be used to update the /etc/hosts file:

        ```ruby
        ruby_block 'edit etc hosts' do
          block do
            rc = Chef::Util::FileEdit.new('/etc/hosts')
            rc.search_file_replace_line(/^127\.0\.0\.1 localhost$/,
              '127.0.0.1 #{new_fqdn} #{new_hostname} localhost')
            rc.write_file
          end
        end
        ```

        **Set environment variables**

        The following example shows how to use variables within a Ruby block to set environment variables using rbenv.

        ```ruby
        node.override[:rbenv][:root] = rbenv_root
        node.override[:ruby_build][:bin_path] = rbenv_binary_path

        ruby_block 'initialize' do
          block do
            ENV['RBENV_ROOT'] = node[:rbenv][:root]
            ENV['PATH'] = "#{node[:rbenv][:root]}/bin:#{node[:ruby_build][:bin_path]}:#{ENV['PATH']}"
          end
        end
        ```

        **Call methods in a gem**

        The following example shows how to call methods in gems not shipped in Chef Infra Client

        ```ruby
        chef_gem 'mongodb'

        ruby_block 'config_replicaset' do
          block do
            MongoDB.configure_replicaset(node, replicaset_name, rs_nodes)
          end
          action :run
        end
        ```
      DOC

      default_action :run
      allowed_actions :create, :run

      def block(&block)
        if block_given? && block
          @block = block
        else
          @block
        end
      end

      property :block_name, String, name_property: true
    end
  end
end
