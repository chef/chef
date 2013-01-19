require 'support/shared/integration/integration_helper'
require 'chef/knife/deps'

describe 'knife deps' do
  extend IntegrationSupport
  include KnifeSupport

  context 'remote' do
    when_the_chef_server 'has a role with no run_list' do
      role 'starring', {}
      it 'knife deps reports no dependencies' do
        knife('deps --remote /roles/starring.json').should_succeed "/roles/starring.json\n"
      end
    end

    when_the_chef_server 'has a role with a default run_list' do
      role 'starring', { 'run_list' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) }
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      it 'knife deps reports all dependencies' do
        knife('deps --remote /roles/starring.json').should_succeed <<EOM
/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
EOM
      end
    end

    when_the_chef_server 'has a role with an env_run_list' do
      role 'starring', { 'env_run_lists' => { 'desert' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) } }
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      it 'knife deps reports all dependencies' do
        knife('deps --remote /roles/starring.json').should_succeed <<EOM
/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
EOM
      end
    end

    when_the_chef_server 'has a node with no environment or run_list' do
      node 'mort', {}
      it 'knife deps reports just the node and _default environment' do
        knife('deps --remote --repo-mode=everything /nodes/mort.json').should_succeed "/environments/_default.json\n/nodes/mort.json\n"
      end
    end
    when_the_chef_server 'has a node with an environment' do
      environment 'desert', {}
      node 'mort', { 'chef_environment' => 'desert' }
      it 'knife deps reports just the node' do
        knife('deps --remote --repo-mode=everything /nodes/mort.json').should_succeed "/environments/desert.json\n/nodes/mort.json\n"
      end
    end
    when_the_chef_server 'has a node with roles and recipes in its run_list' do
      role 'minor', {}
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      cookbook 'soup', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'chicken.rb' => '' } }
      node 'mort', { 'run_list' => %w(role[minor] recipe[quiche] recipe[soup::chicken]) }
      it 'knife deps reports just the node' do
        knife('deps --remote --repo-mode=everything /nodes/mort.json').should_succeed <<EOM
/environments/_default.json
/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/nodes/mort.json
EOM
      end
    end
    when_the_chef_server 'has a cookbook with no dependencies' do
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => '', 'recipes' => { 'default.rb' => '' } }
      it 'knife deps reports just the cookbook' do
        knife('deps --remote /cookbooks/quiche').should_succeed "/cookbooks/quiche\n"
      end
    end
    when_the_chef_server 'has a cookbook with dependencies' do
      cookbook 'kettle', '1.0.0', { 'metadata.rb' => '' }
      cookbook 'quiche', '1.0.0', { 'metadata.rb' => 'depends "kettle"', 'recipes' => { 'default.rb' => '' } }
      it 'knife deps reports just the cookbook' do
        knife('deps --remote /cookbooks/quiche').should_succeed "/cookbooks/kettle\n/cookbooks/quiche\n"
      end
    end
    when_the_chef_server 'has a data bag' do
      data_bag 'bag', { 'item' => {} }
      it 'knife deps reports just the data bag' do
        knife('deps --remote /data_bags/bag/item.json').should_succeed "/data_bags/bag/item.json\n"
      end
    end
    when_the_chef_server 'has an environment' do
      environment 'desert', {}
      it 'knife deps reports just the environment' do
        knife('deps --remote /environments/desert.json').should_succeed "/environments/desert.json\n"
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
        knife('deps --remote --repo-mode=everything /nodes/mort.json').should_succeed <<EOM
/environments/desert.json
/roles/minor.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
/nodes/mort.json
EOM
      end
      it 'knife deps * reports all dependencies of all things' do
        knife('deps --remote --repo-mode=everything /nodes/*').should_succeed <<EOM
/environments/_default.json
/roles/minor.json
/nodes/bart.json
/environments/desert.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
/nodes/mort.json
EOM
      end
      it 'knife deps a b reports all dependencies of a and b' do
        knife('deps --remote --repo-mode=everything /nodes/bart.json /nodes/mort.json').should_succeed <<EOM
/environments/_default.json
/roles/minor.json
/nodes/bart.json
/environments/desert.json
/cookbooks/quiche
/cookbooks/soup
/roles/starring.json
/nodes/mort.json
EOM
      end
      it 'knife deps --tree /* shows dependencies in a tree' do
        knife('deps --remote --tree --repo-mode=everything /nodes/*').should_succeed <<EOM
/nodes/bart.json
  /environments/_default.json
  /roles/minor.json
/nodes/mort.json
  /environments/desert.json
  /roles/starring.json
    /roles/minor.json
    /cookbooks/quiche
    /cookbooks/soup
EOM
      end
      it 'knife deps --tree --no-recurse shows only the first level of dependencies' do
        knife('deps --remote --tree --no-recurse --repo-mode=everything /nodes/*').should_succeed <<EOM
/nodes/bart.json
  /environments/_default.json
  /roles/minor.json
/nodes/mort.json
  /environments/desert.json
  /roles/starring.json
EOM
      end
    end

    context 'circular dependencies' do
      when_the_chef_server 'has cookbooks with circular dependencies' do
        cookbook 'foo', '1.0.0', { 'metadata.rb' => 'depends "bar"' }
        cookbook 'bar', '1.0.0', { 'metadata.rb' => 'depends "baz"' }
        cookbook 'baz', '1.0.0', { 'metadata.rb' => 'depends "foo"' }
        cookbook 'self', '1.0.0', { 'metadata.rb' => 'depends "self"' }
        it 'knife deps prints each once' do
          knife('deps --remote /cookbooks/foo /cookbooks/self').should_succeed <<EOM
/cookbooks/baz
/cookbooks/bar
/cookbooks/foo
/cookbooks/self
EOM
        end
        it 'knife deps --tree prints each once' do
          knife('deps --remote --tree /cookbooks/foo /cookbooks/self').should_succeed <<EOM
/cookbooks/foo
  /cookbooks/bar
    /cookbooks/baz
      /cookbooks/foo
/cookbooks/self
  /cookbooks/self
EOM
        end
      end
      when_the_chef_server 'has roles with circular dependencies' do
        role 'foo', { 'run_list' => [ 'role[bar]' ] }
        role 'bar', { 'run_list' => [ 'role[baz]' ] }
        role 'baz', { 'run_list' => [ 'role[foo]' ] }
        role 'self', { 'run_list' => [ 'role[self]' ] }
        it 'knife deps prints each once' do
          knife('deps --remote /roles/foo.json /roles/self.json').should_succeed <<EOM
/roles/baz.json
/roles/bar.json
/roles/foo.json
/roles/self.json
EOM
        end
        it 'knife deps --tree prints each once' do
          knife('deps --remote --tree /roles/foo.json /roles/self.json') do
            stdout.should == "/roles/foo.json\n  /roles/bar.json\n    /roles/baz.json\n      /roles/foo.json\n/roles/self.json\n  /roles/self.json\n"
            stderr.should == "WARNING: No knife configuration file found\n"
          end
        end
      end
    end

    context 'missing objects' do
      when_the_chef_server 'is empty' do
        it 'knife deps /blah reports an error' do
          knife('deps --remote /blah').should_fail(
            :exit_code => 2,
            :stdout => "/blah\n",
            :stderr => "ERROR: /blah: No such file or directory\n"
          )
        end
        it 'knife deps /roles/x.json reports an error' do
          knife('deps --remote /roles/x.json').should_fail(
            :exit_code => 2,
            :stdout => "/roles/x.json\n",
            :stderr => "ERROR: /roles/x.json: No such file or directory\n"
          )
        end
        it 'knife deps /nodes/x.json reports an error' do
          knife('deps --remote --repo-mode=everything /nodes/x.json').should_fail(
            :exit_code => 2,
            :stdout => "/nodes/x.json\n",
            :stderr => "ERROR: /nodes/x.json: No such file or directory\n"
          )
        end
        it 'knife deps /environments/x.json reports an error' do
          knife('deps --remote /environments/x.json').should_fail(
            :exit_code => 2,
            :stdout => "/environments/x.json\n",
            :stderr => "ERROR: /environments/x.json: No such file or directory\n"
          )
        end
        it 'knife deps /cookbooks/x reports an error' do
          knife('deps --remote /cookbooks/x').should_fail(
            :exit_code => 2,
            :stdout => "/cookbooks/x\n",
            :stderr => "ERROR: /cookbooks/x: No such file or directory\n"
          )
        end
        it 'knife deps /data_bags/bag/item reports an error' do
          knife('deps --remote /data_bags/bag/item').should_fail(
            :exit_code => 2,
            :stdout => "/data_bags/bag/item\n",
            :stderr => "ERROR: /data_bags/bag/item: No such file or directory\n"
          )
        end
      end
      when_the_chef_server 'is missing a dependent cookbook' do
        role 'starring', { 'run_list' => [ 'recipe[quiche]'] }
        it 'knife deps reports the cookbook, along with an error' do
          knife('deps --remote /roles/starring.json').should_fail(
            :exit_code => 2,
            :stdout => "/cookbooks/quiche\n/roles/starring.json\n",
            :stderr => "ERROR: /cookbooks/quiche: No such file or directory\n"
          )
        end
      end
      when_the_chef_server 'is missing a dependent environment' do
        node 'mort', { 'chef_environment' => 'desert' }
        it 'knife deps reports the environment, along with an error' do
          knife('deps --remote --repo-mode=everything /nodes/mort.json').should_fail(
            :exit_code => 2,
            :stdout => "/environments/desert.json\n/nodes/mort.json\n",
            :stderr => "ERROR: /environments/desert.json: No such file or directory\n"
          )
        end
      end
      when_the_chef_server 'is missing a dependent role' do
        role 'starring', { 'run_list' => [ 'role[minor]'] }
        it 'knife deps reports the role, along with an error' do
          knife('deps --remote /roles/starring.json').should_fail(
            :exit_code => 2,
            :stdout => "/roles/minor.json\n/roles/starring.json\n",
            :stderr => "ERROR: /roles/minor.json: No such file or directory\n"
          )
        end
      end
    end
    context 'invalid objects' do
      when_the_chef_server 'is empty' do
        it 'knife deps / reports an error' do
          knife('deps --remote /').should_succeed("/\n")
        end
        it 'knife deps /roles reports an error' do
          knife('deps --remote /roles').should_succeed("/roles\n")
        end
      end
      when_the_chef_server 'has a data bag' do
        data_bag 'bag', { 'item' => {} }
        it 'knife deps /data_bags/bag shows no dependencies' do
          knife('deps --remote /data_bags/bag').should_succeed("/data_bags/bag\n")
        end
      end
      when_the_chef_server 'has a cookbook' do
        cookbook 'blah', '1.0.0', { 'metadata.rb' => '' }
        it 'knife deps on a cookbook file shows no dependencies' do
          knife('deps --remote /cookbooks/blah/metadata.rb').should_succeed(
            "/cookbooks/blah/metadata.rb\n"
          )
        end
      end
    end

    it 'knife deps --no-recurse reports an error' do
      knife('deps --no-recurse /').should_fail("ERROR: --no-recurse requires --tree\n")
    end
  end
end
