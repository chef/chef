#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'support/shared/integration/integration_helper'
require 'support/shared/context/config'
require 'chef/knife/list'

describe 'knife list', :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "is empty" do
    it "knife list / returns all top level directories" do
      knife('list /').should_succeed <<EOM
/clients
/cookbooks
/data_bags
/environments
/nodes
/roles
/users
EOM
    end

    it "knife list -R / returns everything" do
      knife('list -R /').should_succeed <<EOM
/:
clients
cookbooks
data_bags
environments
nodes
roles
users

/clients:
chef-validator.json
chef-webui.json

/cookbooks:

/data_bags:

/environments:
_default.json

/nodes:

/roles:

/users:
admin.json
EOM
    end
  end

  when_the_chef_server "has plenty of stuff in it" do
    before do
      client 'client1', {}
      client 'client2', {}
      cookbook 'cookbook1', '1.0.0'
      cookbook 'cookbook2', '1.0.1', { 'recipes' => { 'default.rb' => '' } }
      data_bag 'bag1', { 'item1' => {}, 'item2' => {} }
      data_bag 'bag2', { 'item1' => {}, 'item2' => {} }
      environment 'environment1', {}
      environment 'environment2', {}
      node 'node1', {}
      node 'node2', {}
      role 'role1', {}
      role 'role2', {}
      user 'user1', {}
      user 'user2', {}
    end

    it "knife list / returns all top level directories" do
      knife('list /').should_succeed <<EOM
/clients
/cookbooks
/data_bags
/environments
/nodes
/roles
/users
EOM
    end

    it "knife list -R / returns everything" do
      knife('list -R /').should_succeed <<EOM
/:
clients
cookbooks
data_bags
environments
nodes
roles
users

/clients:
chef-validator.json
chef-webui.json
client1.json
client2.json

/cookbooks:
cookbook1
cookbook2

/cookbooks/cookbook1:
metadata.rb

/cookbooks/cookbook2:
metadata.rb
recipes

/cookbooks/cookbook2/recipes:
default.rb

/data_bags:
bag1
bag2

/data_bags/bag1:
item1.json
item2.json

/data_bags/bag2:
item1.json
item2.json

/environments:
_default.json
environment1.json
environment2.json

/nodes:
node1.json
node2.json

/roles:
role1.json
role2.json

/users:
admin.json
user1.json
user2.json
EOM
    end

    it "knife list -R --flat / returns everything" do
      knife('list -R --flat /').should_succeed <<EOM
/clients
/clients/chef-validator.json
/clients/chef-webui.json
/clients/client1.json
/clients/client2.json
/cookbooks
/cookbooks/cookbook1
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes
/cookbooks/cookbook2/recipes/default.rb
/data_bags
/data_bags/bag1
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments
/environments/_default.json
/environments/environment1.json
/environments/environment2.json
/nodes
/nodes/node1.json
/nodes/node2.json
/roles
/roles/role1.json
/roles/role2.json
/users
/users/admin.json
/users/user1.json
/users/user2.json
EOM
    end

    it "knife list -Rfp / returns everything" do
      knife('list -Rfp /').should_succeed <<EOM
/clients/
/clients/chef-validator.json
/clients/chef-webui.json
/clients/client1.json
/clients/client2.json
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes/
/cookbooks/cookbook2/recipes/default.rb
/data_bags/
/data_bags/bag1/
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments/
/environments/_default.json
/environments/environment1.json
/environments/environment2.json
/nodes/
/nodes/node1.json
/nodes/node2.json
/roles/
/roles/role1.json
/roles/role2.json
/users/
/users/admin.json
/users/user1.json
/users/user2.json
EOM
    end

    it "knife list /cookbooks returns the list of cookbooks" do
      knife('list /cookbooks').should_succeed <<EOM
/cookbooks/cookbook1
/cookbooks/cookbook2
EOM
    end

    it "knife list /cookbooks/*2/*/*.rb returns the one file" do
      knife('list /cookbooks/*2/*/*.rb').should_succeed "/cookbooks/cookbook2/recipes/default.rb\n"
    end

    it "knife list /**.rb returns all ruby files" do
      knife('list /**.rb').should_succeed <<EOM
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes/default.rb
EOM
    end

    it "knife list /cookbooks/**.rb returns all ruby files" do
      knife('list /cookbooks/**.rb').should_succeed <<EOM
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes/default.rb
EOM
    end

    it "knife list /**.json returns all json files" do
      knife('list /**.json').should_succeed <<EOM
/clients/chef-validator.json
/clients/chef-webui.json
/clients/client1.json
/clients/client2.json
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments/_default.json
/environments/environment1.json
/environments/environment2.json
/nodes/node1.json
/nodes/node2.json
/roles/role1.json
/roles/role2.json
/users/admin.json
/users/user1.json
/users/user2.json
EOM
    end

    it "knife list /data**.json returns all data bag json files" do
      knife('list /data**.json').should_succeed <<EOM
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
EOM
    end

    it "knife list /environments/missing_file.json reports missing file" do
      knife('list /environments/missing_file.json').should_fail "ERROR: /environments/missing_file.json: No such file or directory\n"
    end

    context "missing file/directory exact match tests" do
      it "knife list /blarghle reports missing directory" do
        knife('list /blarghle').should_fail "ERROR: /blarghle: No such file or directory\n"
      end

      it "knife list /roles/blarghle reports missing directory" do
        knife('list /roles/blarghle').should_fail "ERROR: /roles/blarghle: No such file or directory\n"
      end

      it "knife list /roles/blarghle/blorghle reports missing directory" do
        knife('list /roles/blarghle/blorghle').should_fail "ERROR: /roles/blarghle/blorghle: No such file or directory\n"
      end
    end

    context 'symlink tests' do
      when_the_repository 'is empty' do
        context 'when cwd is at the top of the repository' do
          before { cwd '.' }

          it "knife list -Rfp returns everything" do
            knife('list -Rfp').should_succeed <<EOM
clients/
clients/chef-validator.json
clients/chef-webui.json
clients/client1.json
clients/client2.json
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
cookbooks/cookbook2/recipes/
cookbooks/cookbook2/recipes/default.rb
data_bags/
data_bags/bag1/
data_bags/bag1/item1.json
data_bags/bag1/item2.json
data_bags/bag2/
data_bags/bag2/item1.json
data_bags/bag2/item2.json
environments/
environments/_default.json
environments/environment1.json
environments/environment2.json
nodes/
nodes/node1.json
nodes/node2.json
roles/
roles/role1.json
roles/role2.json
users/
users/admin.json
users/user1.json
users/user2.json
EOM
          end
        end
      end

      when_the_repository 'has a cookbooks directory' do
        before { directory 'cookbooks' }
        context 'when cwd is in cookbooks/' do
          before { cwd 'cookbooks' }

          it "knife list -Rfp / returns everything" do
            knife('list -Rfp /').should_succeed <<EOM
/clients/
/clients/chef-validator.json
/clients/chef-webui.json
/clients/client1.json
/clients/client2.json
./
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
/data_bags/
/data_bags/bag1/
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments/
/environments/_default.json
/environments/environment1.json
/environments/environment2.json
/nodes/
/nodes/node1.json
/nodes/node2.json
/roles/
/roles/role1.json
/roles/role2.json
/users/
/users/admin.json
/users/user1.json
/users/user2.json
EOM
          end

          it "knife list -Rfp .. returns everything" do
            knife('list -Rfp ..').should_succeed <<EOM
/clients/
/clients/chef-validator.json
/clients/chef-webui.json
/clients/client1.json
/clients/client2.json
./
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
/data_bags/
/data_bags/bag1/
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments/
/environments/_default.json
/environments/environment1.json
/environments/environment2.json
/nodes/
/nodes/node1.json
/nodes/node2.json
/roles/
/roles/role1.json
/roles/role2.json
/users/
/users/admin.json
/users/user1.json
/users/user2.json
EOM
          end

          it "knife list -Rfp returns cookbooks" do
            knife('list -Rfp').should_succeed <<EOM
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
EOM
          end
        end
      end

      when_the_repository 'has a cookbooks/cookbook2 directory' do
        before { directory 'cookbooks/cookbook2' }

        context 'when cwd is in cookbooks/cookbook2' do
          before { cwd 'cookbooks/cookbook2' }

          it "knife list -Rfp returns cookbooks" do
            knife('list -Rfp').should_succeed <<EOM
metadata.rb
recipes/
recipes/default.rb
EOM
          end
        end
      end

      when_the_repository 'has a cookbooks directory and a symlinked cookbooks directory', :skip => (Chef::Platform.windows?) do
        before do
          directory 'cookbooks'
          symlink 'symlinked', 'cookbooks'
        end

        context 'when cwd is in cookbooks/' do
          before { cwd 'cookbooks' }

          it "knife list -Rfp returns cookbooks" do
            knife('list -Rfp').should_succeed <<EOM
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
EOM
          end
        end

        context 'when cwd is in symlinked/' do
          before { cwd 'symlinked' }

          it "knife list -Rfp returns cookbooks" do
            knife('list -Rfp').should_succeed <<EOM
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
EOM
          end
        end
      end

      when_the_repository 'has a real_cookbooks directory and a cookbooks symlink to it', :skip => (Chef::Platform.windows?) do
        before do
          directory 'real_cookbooks'
          symlink 'cookbooks', 'real_cookbooks'
        end

        context 'when cwd is in real_cookbooks/' do
          before { cwd 'real_cookbooks' }

          it "knife list -Rfp returns cookbooks" do
            knife('list -Rfp').should_succeed <<EOM
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
EOM
          end
        end

        context 'when cwd is in cookbooks/' do
          before { cwd 'cookbooks' }

          it "knife list -Rfp returns cookbooks" do
            knife('list -Rfp').should_succeed <<EOM
cookbook1/
cookbook1/metadata.rb
cookbook2/
cookbook2/metadata.rb
cookbook2/recipes/
cookbook2/recipes/default.rb
EOM
          end
        end
      end
    end
  end

  context "--local" do
    when_the_repository "is empty" do
      it "knife list --local / returns nothing" do
        knife('list --local /').should_succeed ""
      end

      it "knife list /roles returns nothing" do
        knife('list --local /roles').should_fail "ERROR: /roles: No such file or directory\n"
      end
    end

    when_the_repository "has a bunch of stuff" do
      before do
        file 'clients/client1.json', {}
        file 'clients/client2.json', {}

        directory 'cookbooks/cookbook1' do
          file 'metadata.rb', cb_metadata("cookbook1", "1.0.0")
        end
        directory 'cookbooks/cookbook2' do
          file 'metadata.rb', cb_metadata("cookbook2", "2.0.0")
          file 'recipes/default.rb', ''
        end

        directory 'data_bags' do
          directory 'bag1' do
            file 'item1.json', {}
            file 'item2.json', {}
          end
          directory 'bag2' do
            file 'item1.json', {}
            file 'item2.json', {}
          end
        end

        file 'environments/environment1.json', {}
        file 'environments/environment2.json', {}
        file 'nodes/node1.json', {}
        file 'nodes/node2.json', {}
        file 'roles/role1.json', {}
        file 'roles/role2.json', {}
        file 'users/user1.json', {}
        file 'users/user2.json', {}
      end

      it "knife list -Rfp / returns everything" do
        knife('list -Rp --local --flat /').should_succeed <<EOM
/clients/
/clients/client1.json
/clients/client2.json
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes/
/cookbooks/cookbook2/recipes/default.rb
/data_bags/
/data_bags/bag1/
/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments/
/environments/environment1.json
/environments/environment2.json
/nodes/
/nodes/node1.json
/nodes/node2.json
/roles/
/roles/role1.json
/roles/role2.json
/users/
/users/user1.json
/users/user2.json
EOM
      end

      context "missing file/directory tests" do
        it "knife list --local /blarghle reports missing directory" do
          knife('list --local /blarghle').should_fail "ERROR: /blarghle: No such file or directory\n"
        end

        it "knife list /roles/blarghle reports missing directory" do
          knife('list --local /roles/blarghle').should_fail "ERROR: /roles/blarghle: No such file or directory\n"
        end

        it "knife list /roles/blarghle/blorghle reports missing directory" do
          knife('list --local /roles/blarghle/blorghle').should_fail "ERROR: /roles/blarghle/blorghle: No such file or directory\n"
        end
      end
    end
  end

  when_the_chef_server "is in Enterprise mode", :osc_compat => false, :single_org => false do
    before do
      organization 'foo'
    end

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, '/organizations/foo')
    end

    context 'and is empty' do
      it "knife list / returns all top level directories" do
        knife('list /').should_succeed <<EOM
/acls
/clients
/containers
/cookbooks
/data_bags
/environments
/groups
/invitations.json
/members.json
/nodes
/org.json
/roles
EOM
      end

      it "knife list -R / returns everything" do
        knife('list -R /').should_succeed <<EOM
/:
acls
clients
containers
cookbooks
data_bags
environments
groups
invitations.json
members.json
nodes
org.json
roles

/acls:
clients
containers
cookbooks
data_bags
environments
groups
nodes
organization.json
roles

/acls/clients:
foo-validator.json

/acls/containers:
clients.json
containers.json
cookbook_artifacts.json
cookbooks.json
data.json
environments.json
groups.json
nodes.json
policies.json
roles.json
sandboxes.json

/acls/cookbooks:

/acls/data_bags:

/acls/environments:
_default.json

/acls/groups:
admins.json
billing-admins.json
clients.json
users.json

/acls/nodes:

/acls/roles:

/clients:
foo-validator.json

/containers:
clients.json
containers.json
cookbook_artifacts.json
cookbooks.json
data.json
environments.json
groups.json
nodes.json
policies.json
roles.json
sandboxes.json

/cookbooks:

/data_bags:

/environments:
_default.json

/groups:
admins.json
billing-admins.json
clients.json
users.json

/nodes:

/roles:
EOM
      end
    end
  end

  when_the_chef_server "is in Enterprise mode", :osc_compat => false, :single_org => false do
    before do
      organization 'foo'
    end

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, '/organizations/foo')
    end

    it 'knife list -R / returns everything' do
      knife('list -R /').should_succeed <<EOM
/:
acls
clients
containers
cookbooks
data_bags
environments
groups
invitations.json
members.json
nodes
org.json
roles

/acls:
clients
containers
cookbooks
data_bags
environments
groups
nodes
organization.json
roles

/acls/clients:
foo-validator.json

/acls/containers:
clients.json
containers.json
cookbook_artifacts.json
cookbooks.json
data.json
environments.json
groups.json
nodes.json
policies.json
roles.json
sandboxes.json

/acls/cookbooks:

/acls/data_bags:

/acls/environments:
_default.json

/acls/groups:
admins.json
billing-admins.json
clients.json
users.json

/acls/nodes:

/acls/roles:

/clients:
foo-validator.json

/containers:
clients.json
containers.json
cookbook_artifacts.json
cookbooks.json
data.json
environments.json
groups.json
nodes.json
policies.json
roles.json
sandboxes.json

/cookbooks:

/data_bags:

/environments:
_default.json

/groups:
admins.json
billing-admins.json
clients.json
users.json

/nodes:

/roles:
EOM
    end
  end
end
