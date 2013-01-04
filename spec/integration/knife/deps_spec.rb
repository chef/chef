require 'support/shared/integration/integration_helper'
require 'chef/knife/deps'

describe 'knife deps' do
  extend IntegrationSupport
  include KnifeSupport

  context 'remote' do
    when_the_chef_server 'has a role with no run_list' do
      role 'starring', {}
      it 'knife deps reports no dependencies' do
        knife('deps', '--remote', '/roles/starring.json').stdout.should == "/roles/starring.json\n"
      end
    end

    when_the_chef_server 'has a role with a default run_list' do
      role 'starring', { 'run_list' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) }
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      it 'knife deps reports all dependencies' do
        knife('deps', '--remote', '/roles/starring.json').stdout.should == "/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
"
      end
    end

    when_the_chef_server 'has a role with an env_run_list' do
      role 'starring', { 'env_run_lists' => { 'desert' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) } }
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      it 'knife deps reports all dependencies' do
        knife('deps', '--remote', '/roles/starring.json').stdout.should == "/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
"
      end
    end

    when_the_chef_server 'has a node with no environment or run_list' do
      node 'mort', {}
      it 'knife deps reports just the node and _default environment' do
        knife('deps', '--remote', '--repo-mode=everything', '/nodes/mort.json').stdout.should == "/environments/_default.json\n/nodes/mort.json\n"
      end
    end
    when_the_chef_server 'has a node with an environment' do
      environment 'desert', {}
      node 'mort', { 'chef_environment' => 'desert' }
      it 'knife deps reports just the node' do
        knife('deps', '--remote', '--repo-mode=everything', '/nodes/mort.json').stdout.should == "/environments/desert.json\n/nodes/mort.json\n"
      end
    end
    when_the_chef_server 'has a node with roles and recipes in its run_list' do
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      node 'mort', { 'run_list' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) }
      it 'knife deps reports just the node' do
        knife('deps', '--remote', '--repo-mode=everything', '/nodes/mort.json').stdout.should == "/environments/_default.json
/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/nodes/mort.json
"
      end
    end
    when_the_chef_server 'has a cookbook with no dependencies' do
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      it 'knife deps reports just the cookbook' do
        knife('deps', '--remote', '/cookbooks/quiche').stdout.should == "/cookbooks/quiche\n"
      end
    end
    when_the_chef_server 'has a cookbook with dependencies' do
      cookbook 'kettle', '1.0.0', { 'metadata.rb' => '' }
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => 'depends "kettle"', 'recipes' => { 'default.rb' => '' } }
      it 'knife deps reports just the cookbook' do
        knife('deps', '--remote', '/cookbooks/quiche').stdout.should == "/cookbooks/kettle\n/cookbooks/quiche\n"
      end
    end
    when_the_chef_server 'has a data bag' do
      data_bag 'bag', { 'item' => {} }
      it 'knife deps reports just the data bag' do
        knife('deps', '--remote', '/data_bags/bag/item.json').stdout.should == "/data_bags/bag/item.json\n"
      end
    end
    when_the_chef_server 'has an environment' do
      environment 'desert', {}
      it 'knife deps reports just the environment' do
        knife('deps', '--remote', '/environments/desert.json').stdout.should == "/environments/desert.json\n"
      end
    end
    when_the_chef_server 'has a deep dependency tree' do
      role 'starring', { 'run_list' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) }
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      environment 'desert', {}
      node 'mort', { 'chef_environment' => 'desert', 'run_list' => [ 'role[starring]' ] }
      node 'bart', { 'run_list' => [ 'role[minor]' ] }

      it 'knife deps reports all dependencies' do
        knife('deps', '--remote', '--repo-mode=everything', '/nodes/mort.json').stdout.should == "/environments/desert.json
/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
/nodes/mort.json
"
      end
      it 'knife deps * reports all dependencies of all things' do
        knife('deps', '--remote', '--repo-mode=everything', '/nodes/*').stdout.should == "/environments/_default.json
/roles/minor.json
/nodes/bart.json
/environments/desert.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
/nodes/mort.json
"
      end
      it 'knife deps a b reports all dependencies of a and b' do
        knife('deps', '--remote', '--repo-mode=everything', '/nodes/bart.json', '/nodes/mort.json').stdout.should == "/environments/_default.json
/roles/minor.json
/nodes/bart.json
/environments/desert.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
/nodes/mort.json
"
      end
      it 'knife deps --tree /* shows dependencies in a tree' do
        knife('deps', '--remote', '--tree', '--repo-mode=everything', '/nodes/*').stdout.should == "/nodes/bart.json
  /environments/_default.json
  /roles/minor.json
/nodes/mort.json
  /environments/desert.json
  /roles/starring.json
    /roles/minor.json
    /cookbooks/quiche
    /cookbooks/soup
"
      end
      it 'knife deps --tree --no-recurse shows only the first level of dependencies' do
        knife('deps', '--remote', '--tree', '--no-recurse', '--repo-mode=everything', '/nodes/*').stdout.should == "/nodes/bart.json
  /environments/_default.json
  /roles/minor.json
/nodes/mort.json
  /environments/desert.json
  /roles/starring.json
"
      end
    end

    context 'circular dependencies' do
      when_the_chef_server 'has cookbooks with circular dependencies' do
        cookbook 'foo', '1.0.0', { 'metadata.rb' => 'depends "bar"' }
        cookbook 'bar', '1.0.0', { 'metadata.rb' => 'depends "baz"' }
        cookbook 'baz', '1.0.0', { 'metadata.rb' => 'depends "foo"' }
        cookbook 'self', '1.0.0', { 'metadata.rb' => 'depends "self"' }
        it 'knife deps prints each once' do
          knife('deps', '--remote', '/cookbooks/foo', '/cookbooks/self') do
            stdout.should == "/cookbooks/baz\n/cookbooks/bar\n/cookbooks/foo\n/cookbooks/self\n"
            stderr.should == "WARNING: No knife configuration file found\n"
          end
        end
        it 'knife deps --tree prints each once' do
          knife('deps', '--remote', '--tree', '/cookbooks/foo', '/cookbooks/self') do
            stdout.should == "/cookbooks/foo\n  /cookbooks/bar\n    /cookbooks/baz\n      /cookbooks/foo\n/cookbooks/self\n  /cookbooks/self\n"
            stderr.should == "WARNING: No knife configuration file found\n"
          end
        end
      end
      when_the_chef_server 'has roles with circular dependencies' do
        role 'foo', { 'run_list' => [ 'role[bar]' ] }
        role 'bar', { 'run_list' => [ 'role[baz]' ] }
        role 'baz', { 'run_list' => [ 'role[foo]' ] }
        role 'self', { 'run_list' => [ 'role[self]' ] }
        it 'knife deps prints each once' do
          knife('deps', '--remote', '/roles/foo.json', '/roles/self.json') do
            stdout.should == "/roles/baz.json\n/roles/bar.json\n/roles/foo.json\n/roles/self.json\n"
            stderr.should == "WARNING: No knife configuration file found\n"
          end
        end
        it 'knife deps --tree prints each once' do
          knife('deps', '--remote', '--tree', '/roles/foo.json', '/roles/self.json') do
            stdout.should == "/roles/foo.json\n  /roles/bar.json\n    /roles/baz.json\n      /roles/foo.json\n/roles/self.json\n  /roles/self.json\n"
            stderr.should == "WARNING: No knife configuration file found\n"
          end
        end
      end
    end

    context 'missing objects' do
      when_the_chef_server 'is empty' do
        it 'knife deps /blah reports an error' do
          knife('deps', '--remote', '/blah') do
            stdout.should == "/blah\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /blah: No such file or directory\n"
          end
        end
        it 'knife deps /roles/x.json reports an error' do
          knife('deps', '--remote', '/roles/x.json') do
            stdout.should == "/roles/x.json\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /roles/x.json: No such file or directory\n"
          end
        end
        it 'knife deps /nodes/x.json reports an error' do
          knife('deps', '--remote', '--repo-mode=everything', '/nodes/x.json') do
            stdout.should == "/nodes/x.json\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /nodes/x.json: No such file or directory\n"
          end
        end
        it 'knife deps /environments/x.json reports an error' do
          knife('deps', '--remote', '/environments/x.json') do
            stdout.should == "/environments/x.json\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /environments/x.json: No such file or directory\n"
          end
        end
        it 'knife deps /cookbooks/x reports an error' do
          knife('deps', '--remote', '/cookbooks/x') do
            stdout.should == "/cookbooks/x\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /cookbooks/x: No such file or directory\n"
          end
        end
        it 'knife deps /data_bags/bag/item reports an error' do
          knife('deps', '--remote', '/data_bags/bag/item') do
            stdout.should == "/data_bags/bag/item\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /data_bags/bag/item: No such file or directory\n"
          end
        end
      end
      when_the_chef_server 'is missing a dependent cookbook' do
        role 'starring', { 'run_list' => [ 'recipe[quiche]'] }
        it 'knife deps reports the cookbook, along with an error' do
          knife('deps', '--remote', '/roles/starring.json') do
            stdout.should == "/cookbooks/quiche\n/roles/starring.json\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /cookbooks/quiche: No such file or directory\n"
          end
        end
      end
      when_the_chef_server 'is missing a dependent environment' do
        node 'mort', { 'chef_environment' => 'desert' }
        it 'knife deps reports the environment, along with an error' do
          knife('deps', '--remote', '--repo-mode=everything', '/nodes/mort.json') do
            stdout.should == "/environments/desert.json\n/nodes/mort.json\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /environments/desert.json: No such file or directory\n"
          end
        end
      end
      when_the_chef_server 'is missing a dependent role' do
        role 'starring', { 'run_list' => [ 'role[minor]'] }
        it 'knife deps reports the role, along with an error' do
          knife('deps', '--remote', '/roles/starring.json') do
            stdout.should == "/roles/minor.json\n/roles/starring.json\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /roles/minor.json: No such file or directory\n"
          end
        end
      end
    end
    context 'invalid objects' do
      when_the_chef_server 'is empty' do
        it 'knife deps / reports an error' do
          knife('deps', '--remote', '/') do
            stdout.should == "/\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: / is not a Chef object!\n"
          end
        end
        it 'knife deps /roles reports an error' do
          knife('deps', '--remote', '/roles') do
            stdout.should == "/roles\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /roles is not a Chef object!\n"
          end
        end
      end
      when_the_chef_server 'has a data bag' do
        data_bag 'bag', { 'item' => {} }
        it 'knife deps /data_bags/bag returns an error' do
          knife('deps', '--remote', '/data_bags/bag') do
            stdout.should == "/data_bags/bag\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /data_bags/bag is not a Chef object!\n"
          end
        end
      end
      when_the_chef_server 'has a cookbook' do
        cookbook 'blah', '1.0.0', { 'metadata.rb' => '' }
        it 'knife deps on a cookbook file returns an error' do
          knife('deps', '--remote', '/cookbooks/blah/metadata.rb') do
            stdout.should == "/cookbooks/blah/metadata.rb\n"
            stderr.should == "WARNING: No knife configuration file found\nERROR: /cookbooks/blah/metadata.rb is not a Chef object!\n"
          end
        end
      end
    end

    it 'knife deps --no-recurse reports an error' do
      knife('deps', '--no-recurse', '/') do
        stdout.should == ""
        stderr.should == "WARNING: No knife configuration file found\nERROR: --no-recurse requires --tree\n"
        exit_code.should == 1
      end
    end
  end
end
