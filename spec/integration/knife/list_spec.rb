require 'support/shared/integration/integration_helper'
require 'chef/knife/list'

describe 'knife list' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server "is empty" do
    it "knife list / returns all top level directories" do
      knife('list', '/').stdout.should == "/cookbooks
/data_bags
/environments
/roles
"
    end

    it "knife list -R / returns everything" do
      knife('list', '-R', '/').stdout.should == "/:
cookbooks
data_bags
environments
roles

/cookbooks:

/data_bags:

/environments:
_default.json

/roles:
"
    end
  end

  when_the_chef_server "has plenty of stuff in it" do
    client 'client1', {}
    client 'client2', {}
    cookbook 'cookbook1', '1.0.0', { 'metadata.rb' => '' }
    cookbook 'cookbook2', '1.0.1', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
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

    it "knife list / returns all top level directories" do
      knife('list', '/').stdout.should == "/cookbooks
/data_bags
/environments
/roles
"
    end

    it "knife list -R / returns everything" do
      knife('list', '-R', '/').stdout.should == "/:
cookbooks
data_bags
environments
roles

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

/roles:
role1.json
role2.json
"
    end

    it "knife list -R --flat / returns everything" do
      knife('list', '-R', '--flat', '/').stdout.should == "/cookbooks
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
/roles
/roles/role1.json
/roles/role2.json
"
    end

    it "knife list -Rp --flat / returns everything" do
      knife('list', '-Rp', '--flat', '/').stdout.should == "/cookbooks/
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
/roles/
/roles/role1.json
/roles/role2.json
"
    end

    it "knife list /cookbooks returns the list of cookbooks" do
      knife('list', '/cookbooks').stdout.should == "/cookbooks/cookbook1
/cookbooks/cookbook2
"
    end

    it "knife list /cookbooks/*2/*/*.rb returns the one file" do
      knife('list', '/cookbooks/*2/*/*.rb').stdout.should == "/cookbooks/cookbook2/recipes/default.rb\n"
    end

    it "knife list /**.rb returns all ruby files" do
      knife('list', '/**.rb').stdout.should == "/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes/default.rb
"
    end

    it "knife list /cookbooks/**.rb returns all ruby files" do
      knife('list', '/cookbooks/**.rb').stdout.should == "/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/metadata.rb
/cookbooks/cookbook2/recipes/default.rb
"
    end

    it "knife list /**.json returns all json files" do
      knife('list', '/**.json').stdout.should == "/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
/environments/_default.json
/environments/environment1.json
/environments/environment2.json
/roles/role1.json
/roles/role2.json
"
    end

    it "knife list /data**.json returns all data bag json files" do
      knife('list', '/data**.json').stdout.should == "/data_bags/bag1/item1.json
/data_bags/bag1/item2.json
/data_bags/bag2/item1.json
/data_bags/bag2/item2.json
"
    end

    it "knife list /environments/missing_file.json reports missing file" do
      knife('list', '/environments/missing_file.json') do
        stderr.should == "WARNING: No knife configuration file found
ERROR: /environments/missing_file.json: No such file or directory
"
        stdout.should == ''
      end
    end

    context "missing file/directory exact match tests" do
      it "knife list /blarghle reports missing directory" do
        knife('list', '/blarghle') do
          stderr.should == "WARNING: No knife configuration file found
ERROR: /blarghle: No such file or directory
"
          stdout.should == ''
        end
      end

      it "knife list /roles/blarghle reports missing directory" do
        knife('list', '/roles/blarghle') do
          stderr.should == "WARNING: No knife configuration file found
ERROR: /roles/blarghle: No such file or directory
"
          stdout.should == ''
        end
      end

      it "knife list /roles/blarghle/blorghle reports missing directory" do
        knife('list', '/roles/blarghle/blorghle') do
          stderr.should == "WARNING: No knife configuration file found
ERROR: /roles/blarghle/blorghle: No such file or directory
"
          stdout.should == ''
        end
      end
    end
  end

  context "--local" do
    when_the_repository "is empty" do
      it "knife list --local / returns nothing" do
        knife('list', '--local', '/').stdout.should == ""
      end

      it "knife list /roles returns nothing" do
        knife('list', '--local', '/roles').stdout.should == ""
      end
    end

    when_the_repository "has a bunch of stuff" do
      file 'clients/client1.json', {}
      file 'clients/client2.json', {}

      directory 'cookbooks/cookbook1' do
        file 'metadata.rb', ''
      end
      directory 'cookbooks/cookbook2' do
        file 'metadata.rb', ''
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

      it "knife list -Rp --flat / returns everything" do
        knife('list', '-Rp', '--flat', '/').stdout.should == "/cookbooks/
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
/roles/
/roles/role1.json
/roles/role2.json
"
      end

      context "missing file/directory tests" do
        it "knife list --local /blarghle reports missing directory" do
          knife('list', '--local', '/blarghle') do
            stderr.should == "WARNING: No knife configuration file found
ERROR: /blarghle: No such file or directory
"
            stdout.should == ''
          end
        end

        it "knife list /roles/blarghle reports missing directory" do
          knife('list', '--local', '/roles/blarghle') do
            stderr.should == "WARNING: No knife configuration file found
ERROR: /roles/blarghle: No such file or directory
"
            stdout.should == ''
          end
        end

        it "knife list /roles/blarghle/blorghle reports missing directory" do
          knife('list', '--local', '/roles/blarghle/blorghle') do
            stderr.should == "WARNING: No knife configuration file found
ERROR: /roles/blarghle/blorghle: No such file or directory
"
            stdout.should == ''
          end
        end
      end
    end

    when_the_repository "has empty roles, environments and data bag item directories" do
      directory "roles"
      directory "environments"
      directory "data_bags/bag1"

      it "knife list --local -R / returns them" do
        knife('list', '--local', '-R', '/').stdout.should == "/:
data_bags
environments
roles

/data_bags:
bag1

/data_bags/bag1:

/environments:

/roles:
"
      end
    end

    when_the_repository "has an empty data_bags directory" do
      directory "data_bags"

      it "knife list --local / returns it" do
        knife('list', '--local', '/').stdout.should == "/data_bags\n"
      end
    end

    when_the_repository "has an empty cookbook directory" do
      directory 'cookbooks/cookbook1'

      it "knife list --local -R / does not return it" do
        knife('list', '--local', '-R', '/').stdout.should == "/:
cookbooks

/cookbooks:
"
      end
    end

    when_the_repository "has only empty cookbook subdirectories" do
      directory 'cookbooks/cookbook1/recipes'

      it "knife list --local -R / does not return it" do
        pending 'figure out if knife cookbook upload -a ignores it too' do
          knife('list', '--local', '-R', '/').stdout.should == "/:
cookbooks

/cookbooks:
"
        end
      end
    end

    when_the_repository "has empty and non-empty cookbook subdirectories" do
      directory 'cookbooks/cookbook1/recipes'
      file 'cookbooks/cookbook1/templates/default/x.txt', ''

      it "knife list --local -R / does not return the empty ones" do
        knife('list', '--local', '-R', '/').stdout.should == "/:
cookbooks

/cookbooks:
cookbook1

/cookbooks/cookbook1:
templates

/cookbooks/cookbook1/templates:
default

/cookbooks/cookbook1/templates/default:
x.txt
"
      end
    end

    when_the_repository "has only empty cookbook sub-sub-directories" do
      directory 'cookbooks/cookbook1/templates/default'

      it "knife list --local -R / does not return it" do
        pending 'figure out if knife cookbook upload -a ignores it too' do
          knife('list', '--local', '-R', '/').stdout.should == "/:
cookbooks

/cookbooks:
"
        end
      end
    end

    when_the_repository "has empty cookbook sub-sub-directories alongside non-empty ones" do
      file 'cookbooks/cookbook1/templates/default/x.txt', ''
      directory 'cookbooks/cookbook1/templates/rhel'
      directory 'cookbooks/cookbook1/files/default'

      it "knife list --local -R / does not return the empty ones" do
        pending 'exclude directories with only empty children' do
          knife('list', '--local', '-R', '/').stdout.should == "/:
cookbooks

/cookbooks:
cookbook1

/cookbooks/cookbook1:
templates

/cookbooks/cookbook1/:
default

/cookbooks/cookbook1/templates/default:
x.txt
"
        end
      end
    end

    when_the_repository "has an extra schmenvironments directory" do
      directory "schmenvironments" do
        file "_default.json", {}
      end

      it "knife list --local -R / should NOT return it" do
        knife('list', '--local', '-R', '/').stdout.should == ""
      end
    end

    when_the_repository "has extra subdirectories and files under data bag items, roles, and environments" do
      directory "data_bags/bag1" do
        file "item1.json", {}
        file "item2.xml", ""
        file "another_subdir/item.json", {}
      end
      directory "roles" do
        file "role1.json", {}
        file "role2.xml", ""
        file "subdir/role.json", {}
      end
      directory "environments" do
        file "environment1.json", {}
        file "environment2.xml", ""
        file "subdir/environment.json", {}
      end

      it "knife list --local -R / should NOT return them" do
        pending "Decide whether this is a good/bad idea" do
          knife('list', '--local', '-R', '/').stdout.should == "/:
data_bags
environments
roles

/data_bags:
bag1

/data_bags/bag1:
item1.json

/environments:
environment1.json

/roles:
role1.json
"
        end
      end
    end

    when_the_repository "has extraneous subdirectories and files under cookbooks" do
      directory 'cookbooks/cookbook1' do
        file 'a.rb', ''
        file 'blarghle/blah.rb', ''
        directory 'attributes' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'definitions' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'recipes' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'libraries' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'templates' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'files' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'resources' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
        directory 'providers' do
          file 'a.rb', ''
          file 'b.json', {}
          file 'c/d.rb', ''
          file 'c/e.json', {}
        end
      end

      it "knife list --local -R / should NOT return them" do
        pending "Decide whether this is a good idea" do
          knife('list', '--local', '-R', '/').stdout.should == "/:
cookbooks

/cookbooks:
cookbook1

/cookbooks/cookbook1:
a.rb
attributes
definitions
files
libraries
providers
recipes
resources
templates

/cookbooks/cookbook1/attributes:
a.rb

/cookbooks/cookbook1/definitions:
a.rb

/cookbooks/cookbook1/files:
a.rb
b.json
c

/cookbooks/cookbook1/files/c:
d.rb
e.json

/cookbooks/cookbook1/libraries:
a.rb

/cookbooks/cookbook1/providers:
a.rb
c

/cookbooks/cookbook1/providers/c:
d.rb

/cookbooks/cookbook1/recipes:
a.rb

/cookbooks/cookbook1/resources:
a.rb
c

/cookbooks/cookbook1/resources/c:
d.rb

/cookbooks/cookbook1/templates:
a.rb
b.json
c

/cookbooks/cookbook1/templates/c:
d.rb
e.json
"
        end
      end
    end

    # TODO chefignore
    # TODO alternate repo_path / *_path
  end
end
