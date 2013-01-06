require 'support/shared/integration/integration_helper'
require 'chef/knife/list'
require 'chef/knife/show'

describe 'General chef_repo file system checks' do
  extend IntegrationSupport
  include KnifeSupport

  context 'directories and files that should/should not be ignored' do
    when_the_repository "has empty roles, environments and data bag item directories" do
      directory "roles"
      directory "environments"
      directory "data_bags/bag1"

      it "knife list --local -Rfp / returns them" do
        knife('list --local -Rfp /').should_succeed <<EOM
/data_bags/
/data_bags/bag1/
/environments/
/roles/
EOM
      end
    end

    when_the_repository "has an empty data_bags directory" do
      directory "data_bags"

      it "knife list --local / returns it" do
        knife('list --local /').should_succeed "/data_bags\n"
      end
    end

    when_the_repository "has an empty cookbook directory" do
      directory 'cookbooks/cookbook1'

      it "knife list --local -Rfp / does not return it" do
        knife('list --local -Rfp /').should_succeed(<<EOM, :stderr => "WARN: Cookbook 'cookbook1' is empty or entirely chefignored at #{Chef::Config.chef_repo_path}/cookbooks/cookbook1\n")
/cookbooks/
EOM
      end
    end

    when_the_repository "has only empty cookbook subdirectories" do
      directory 'cookbooks/cookbook1/recipes'

      it "knife list --local -Rfp / does not return it" do
        knife('list --local -Rfp /').should_succeed(<<EOM, :stderr => "WARN: Cookbook 'cookbook1' is empty or entirely chefignored at #{Chef::Config.chef_repo_path}/cookbooks/cookbook1\n")
/cookbooks/
EOM
      end
    end

    when_the_repository "has empty and non-empty cookbook subdirectories" do
      directory 'cookbooks/cookbook1/recipes'
      file 'cookbooks/cookbook1/templates/default/x.txt', ''

      it "knife list --local -Rfp / does not return the empty ones" do
        knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/templates/
/cookbooks/cookbook1/templates/default/
/cookbooks/cookbook1/templates/default/x.txt
EOM
      end
    end

    when_the_repository "has only empty cookbook sub-sub-directories" do
      directory 'cookbooks/cookbook1/templates/default'

      it "knife list --local -Rfp / does not return it" do
        knife('list --local -Rfp /').should_succeed(<<EOM, :stderr => "WARN: Cookbook 'cookbook1' is empty or entirely chefignored at #{Chef::Config.chef_repo_path}/cookbooks/cookbook1\n")
/cookbooks/
EOM
      end
    end

    when_the_repository "has empty cookbook sub-sub-directories alongside non-empty ones" do
      file 'cookbooks/cookbook1/templates/default/x.txt', ''
      directory 'cookbooks/cookbook1/templates/rhel'
      directory 'cookbooks/cookbook1/files/default'

      it "knife list --local -Rfp / does not return the empty ones" do
        knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/templates/
/cookbooks/cookbook1/templates/default/
/cookbooks/cookbook1/templates/default/x.txt
EOM
      end
    end

    when_the_repository "has an extra schmenvironments directory" do
      directory "schmenvironments" do
        file "_default.json", {}
      end

      it "knife list --local -Rfp / should NOT return it" do
        knife('list --local -Rfp /').should_succeed ""
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

      it "knife list --local -Rfp / should NOT return them" do
        pending "Decide whether this is a good/bad idea" do
          knife('list --local -Rfp /').should_succeed <<EOM
/data_bags/
/data_bags/bag1/
/data_bags/bag1/item1.json
/environments/
/environments/environment1.json
/roles/
/roles/role1.json
EOM
        end
      end
    end

    when_the_repository "has extraneous subdirectories and files under a cookbook" do
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

      it "knife list --local -Rfp / should NOT return them" do
        pending "Decide whether this is a good idea" do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/a.rb
/cookbooks/cookbook1/attributes/
/cookbooks/cookbook1/attributes/a.rb
/cookbooks/cookbook1/definitions/
/cookbooks/cookbook1/definitions/a.rb
/cookbooks/cookbook1/files/
/cookbooks/cookbook1/files/a.rb
/cookbooks/cookbook1/files/b.json
/cookbooks/cookbook1/files/c/
/cookbooks/cookbook1/files/c/d.rb
/cookbooks/cookbook1/files/c/e.json
/cookbooks/cookbook1/libraries/
/cookbooks/cookbook1/libraries/a.rb
/cookbooks/cookbook1/providers/
/cookbooks/cookbook1/providers/a.rb
/cookbooks/cookbook1/providers/c/
/cookbooks/cookbook1/providers/c/d.rb
/cookbooks/cookbook1/recipes/
/cookbooks/cookbook1/recipes/a.rb
/cookbooks/cookbook1/resources/
/cookbooks/cookbook1/resources/a.rb
/cookbooks/cookbook1/resources/c/
/cookbooks/cookbook1/resources/c/d.rb
/cookbooks/cookbook1/templates/
/cookbooks/cookbook1/templates/a.rb
/cookbooks/cookbook1/templates/b.json
/cookbooks/cookbook1/templates/c/
/cookbooks/cookbook1/templates/c/d.rb
/cookbooks/cookbook1/templates/c/e.json
EOM
        end
      end
    end

    when_the_repository "has a file in cookbooks/" do
      file 'cookbooks/file', ''
      it 'does not show up in list -Rfp' do
        knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
EOM
      end
    end

    when_the_repository "has a file in data_bags/" do
      file 'data_bags/file', ''
      it 'does not show up in list -Rfp' do
        pending "don't show files when only directories are allowed" do
          knife('list --local -Rfp /').should_succeed <<EOM
/data_bags/
EOM
        end
      end
    end
  end

  context 'chefignore tests' do
    when_the_repository "has lots of stuff in it" do
      file 'roles/x.json', {}
      file 'environments/x.json', {}
      file 'data_bags/bag1/x.json', {}
      file 'cookbooks/cookbook1/x.json', {}

      context "and has a chefignore everywhere except cookbooks" do
        chefignore = "x.json\nroles/x.json\nenvironments/x.json\ndata_bags/bag1/x.json\nbag1/x.json\ncookbooks/cookbook1/x.json\ncookbook1/x.json\n"
        file 'chefignore', chefignore
        file 'roles/chefignore', chefignore
        file 'environments/chefignore', chefignore
        file 'data_bags/chefignore', chefignore
        file 'data_bags/bag1/chefignore', chefignore
        file 'cookbooks/cookbook1/chefignore', chefignore

        it 'nothing is ignored' do
          # NOTE: many of the "chefignore" files should probably not show up
          # themselves, but we have other tests that talk about that
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/chefignore
/cookbooks/cookbook1/x.json
/data_bags/
/data_bags/bag1/
/data_bags/bag1/chefignore
/data_bags/bag1/x.json
/data_bags/chefignore
/environments/
/environments/chefignore
/environments/x.json
/roles/
/roles/chefignore
/roles/x.json
EOM
        end
      end
    end

    when_the_repository 'has a cookbook with only chefignored files' do
      file 'cookbooks/cookbook1/templates/default/x.rb', ''
      file 'cookbooks/cookbook1/libraries/x.rb', ''
      file 'cookbooks/chefignore', "libraries/x.rb\ntemplates/default/x.rb\n"

      it 'the cookbook is not listed' do
        knife('list --local -Rfp /').should_succeed(<<EOM, :stderr => "WARN: Cookbook 'cookbook1' is empty or entirely chefignored at #{Chef::Config.chef_repo_path}/cookbooks/cookbook1\n")
/cookbooks/
EOM
      end
    end

    when_the_repository "has multiple cookbooks" do
      file 'cookbooks/cookbook1/x.json', {}
      file 'cookbooks/cookbook1/y.json', {}
      file 'cookbooks/cookbook2/x.json', {}
      file 'cookbooks/cookbook2/y.json', {}

      context 'and has a chefignore with filenames' do
        file 'cookbooks/chefignore', "x.json\n"

        it 'matching files and directories get ignored in all cookbooks' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/y.json
EOM
        end
      end

      context "and has a chefignore with wildcards" do
        file 'cookbooks/chefignore', "x.*\n"
        file 'cookbooks/cookbook1/x.rb', ''

        it 'matching files and directories get ignored in all cookbooks' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/y.json
EOM
        end
      end

      context "and has a chefignore with relative paths" do
        file 'cookbooks/cookbook1/recipes/x.rb', ''
        file 'cookbooks/cookbook2/recipes/y.rb', ''
        file 'cookbooks/chefignore', "recipes/x.rb\n"

        it 'matching directories get ignored' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/x.json
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/recipes/
/cookbooks/cookbook2/recipes/y.rb
/cookbooks/cookbook2/x.json
/cookbooks/cookbook2/y.json
EOM
        end
      end

      context "and has a chefignore with subdirectories" do
        file 'cookbooks/cookbook1/recipes/y.rb', ''
        file 'cookbooks/chefignore', "recipes\nrecipes/\n"

        it 'matching directories do NOT get ignored' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/recipes/
/cookbooks/cookbook1/recipes/y.rb
/cookbooks/cookbook1/x.json
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/x.json
/cookbooks/cookbook2/y.json
EOM
        end
      end

      context "and has a chefignore that ignores all files in a subdirectory" do
        file 'cookbooks/cookbook1/templates/default/x.rb', ''
        file 'cookbooks/cookbook1/libraries/x.rb', ''
        file 'cookbooks/chefignore', "libraries/x.rb\ntemplates/default/x.rb\n"

        it 'ignores the subdirectory entirely' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/x.json
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/x.json
/cookbooks/cookbook2/y.json
EOM
        end
      end

      context "and has an empty chefignore" do
        file 'cookbooks/chefignore', "\n"

        it 'nothing is ignored' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/x.json
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/x.json
/cookbooks/cookbook2/y.json
EOM
        end
      end

      context "and has a chefignore with comments and empty lines" do
        file 'cookbooks/chefignore', "\n\n # blah\n#\nx.json\n\n"

        it 'matching files and directories get ignored in all cookbooks' do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/cookbook1/
/cookbooks/cookbook1/y.json
/cookbooks/cookbook2/
/cookbooks/cookbook2/y.json
EOM
        end
      end
    end

    when_the_repository "has multiple cookbook paths" do
      before :each do
        Chef::Config.cookbook_path = [
          File.join(Chef::Config.chef_repo_path, 'cookbooks1'),
          File.join(Chef::Config.chef_repo_path, 'cookbooks2')
        ]
      end

      file 'cookbooks1/mycookbook/metadata.rb', ''
      file 'cookbooks1/mycookbook/x.json', {}
      file 'cookbooks2/yourcookbook/metadata.rb', ''
      file 'cookbooks2/yourcookbook/x.json', ''

      context "and multiple chefignores" do
        file 'cookbooks1/chefignore', "metadata.rb\n"
        file 'cookbooks2/chefignore', "x.json\n"
        it "chefignores apply only to the directories they are in" do
          knife('list --local -Rfp /').should_succeed <<EOM
/cookbooks/
/cookbooks/mycookbook/
/cookbooks/mycookbook/x.json
/cookbooks/yourcookbook/
/cookbooks/yourcookbook/metadata.rb
EOM
        end

        context "and conflicting cookbooks" do
          file 'cookbooks1/yourcookbook/metadata.rb', ''
          file 'cookbooks1/yourcookbook/x.json', ''
          file 'cookbooks1/yourcookbook/onlyincookbooks1.rb', ''
          file 'cookbooks2/yourcookbook/onlyincookbooks2.rb', ''

          it "chefignores apply only to the winning cookbook" do
            knife('list --local -Rfp /').should_succeed(<<EOM, :stderr => "WARN: Child with name 'yourcookbook' found in multiple directories: #{Chef::Config.chef_repo_path}/cookbooks1/yourcookbook and #{Chef::Config.chef_repo_path}/cookbooks2/yourcookbook\n")
/cookbooks/
/cookbooks/mycookbook/
/cookbooks/mycookbook/x.json
/cookbooks/yourcookbook/
/cookbooks/yourcookbook/onlyincookbooks1.rb
/cookbooks/yourcookbook/x.json
EOM
          end
        end
      end
    end

    when_the_repository 'has a cookbook named chefignore' do
      file 'cookbooks/chefignore/metadata.rb', {}
      it 'knife list -Rfp /cookbooks shows it' do
        knife('list --local -Rfp /cookbooks').should_succeed <<EOM
/cookbooks/chefignore/
/cookbooks/chefignore/metadata.rb
EOM
      end
    end

    when_the_repository 'has multiple cookbook paths, one with a chefignore file and the other with a cookbook named chefignore' do
      file 'cookbooks1/chefignore', ''
      file 'cookbooks1/blah/metadata.rb', ''
      file 'cookbooks2/chefignore/metadata.rb', ''
      before :each do
        Chef::Config.cookbook_path = [
          File.join(Chef::Config.chef_repo_path, 'cookbooks1'),
          File.join(Chef::Config.chef_repo_path, 'cookbooks2')
        ]
      end
      it 'knife list -Rfp /cookbooks shows the chefignore cookbook' do
        knife('list --local -Rfp /cookbooks').should_succeed <<EOM
/cookbooks/blah/
/cookbooks/blah/metadata.rb
/cookbooks/chefignore/
/cookbooks/chefignore/metadata.rb
EOM
      end
    end
  end

  # TODO alternate repo_path / *_path
  context 'alternate *_path' do
    when_the_repository 'has clients and clients2, cookbooks and cookbooks2, etc.' do
      file 'clients/client1.json', {}
      file 'cookbooks/cookbook1/metadata.rb', ''
      file 'data_bags/bag/item.json', {}
      file 'environments/env1.json', {}
      file 'nodes/node1.json', {}
      file 'roles/role1.json', {}
      file 'users/user1.json', {}

      file 'clients2/client1.json', {}
      file 'cookbooks2/cookbook2/metadata.rb', ''
      file 'data_bags2/bag2/item2.json', {}
      file 'environments2/env2.json', {}
      file 'nodes2/node2.json', {}
      file 'roles2/role2.json', {}
      file 'users2/user2.json', {}

      directory 'chef_repo2' do
        file 'clients/client3.json', {}
        file 'cookbooks/cookbook3/metadata.rb', ''
        file 'data_bags/bag3/item3.json', {}
        file 'environments/env3.json', {}
        file 'nodes/node3.json', {}
        file 'roles/role3.json', {}
        file 'users/user3.json', {}
      end

      context 'when all _paths are set to alternates' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = File.join(Chef::Config.chef_repo_path, "#{object_name}s2")
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
data_bags/
data_bags/bag2/
data_bags/bag2/item2.json
environments/
environments/env2.json
roles/
roles/role2.json
EOM
          end
        end

        context 'when cwd is inside data_bags2' do
          cwd 'data_bags2'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag2/
bag2/item2.json
EOM
          end
          it 'knife list --local -Rfp ../roles lists roles' do
            knife('list --local -Rfp ../roles').should_succeed "/roles/role2.json\n"
          end
        end
      end

      context 'when all _paths except chef_repo_path are set to alternates' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = File.join(Chef::Config.chef_repo_path, "#{object_name}s2")
          end
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
data_bags/
data_bags/bag2/
data_bags/bag2/item2.json
environments/
environments/env2.json
roles/
roles/role2.json
EOM
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside data_bags2' do
          cwd 'data_bags2'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag2/
bag2/item2.json
EOM
          end
        end
      end

      context 'when only chef_repo_path is set to its alternate' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env3.json
roles/
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when paths are set to point to both versions of each' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = [
              File.join(Chef::Config.chef_repo_path, "#{object_name}s"),
              File.join(Chef::Config.chef_repo_path, "#{object_name}s2")
            ]
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when there is a directory in clients1 and file in clients2 with the same name' do
          directory 'clients/blah.json'
          file 'clients2/blah.json', {}
          it 'knife show /clients/blah.json succeeds' do
            pending "don't count directories in clients" do
              knife('show --local /clients/blah.json').should_succeed ''
            end
          end
        end

        context 'when there is a file in cookbooks1 and directory in cookbooks2 with the same name' do
          file 'cookbooks/blah', ''
          file 'cookbooks2/blah/metadata.rb', ''
          it 'knife list -Rfp cookbooks shows files in blah' do
            knife('list --local -Rfp /cookbooks').should_succeed <<EOM
/cookbooks/blah/
/cookbooks/blah/metadata.rb
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
EOM
          end
        end

        context 'when there is an empty directory in cookbooks1 and a real cookbook in cookbooks2 with the same name' do
          directory 'cookbooks/blah'
          file 'cookbooks2/blah/metadata.rb', ''
          it 'knife list -Rfp cookbooks shows files in blah' do
            knife('list --local -Rfp /cookbooks').should_succeed(<<EOM, :stderr => "WARN: Cookbook 'blah' is empty or entirely chefignored at #{Chef::Config.cookbook_path[0]}/blah\n")
/cookbooks/blah/
/cookbooks/blah/metadata.rb
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
EOM
          end
        end

        context 'when there is a cookbook in cookbooks1 and a cookbook in cookbooks2 with the same name' do
          file 'cookbooks/blah/metadata.json', {}
          file 'cookbooks2/blah/metadata.rb', ''
          it 'knife list -Rfp cookbooks shows files in the first cookbook and not the second' do
            knife('list --local -Rfp /cookbooks').should_succeed(<<EOM, :stderr => "WARN: Child with name 'blah' found in multiple directories: #{Chef::Config.cookbook_path[0]}/blah and #{Chef::Config.cookbook_path[1]}/blah\n")
/cookbooks/blah/
/cookbooks/blah/metadata.json
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
EOM
          end
        end

        context 'when there is a file in data_bags1 and a directory in data_bags2 with the same name' do
          file 'data_bags/blah', ''
          file 'data_bags2/blah/item.json', ''
          it 'knife list -Rfp data_bags shows files in blah' do
            pending "Don't count files as data bags" do
              knife('list --local -Rfp /data_bags').should_succeed <<EOM
/data_bags/bag/
/data_bags/bag/item.json
/data_bags/bag2/
/data_bags/bag2/item2.json
/data_bags/blah/
/data_bags/blah/item1.json
EOM
            end
          end
        end

        context 'when there is a data bag in data_bags1 and a data bag in data_bags2 with the same name' do
          file 'data_bags/blah/item1.json', ''
          file 'data_bags2/blah/item2.json', ''
          it 'knife list -Rfp data_bags shows only items in data_bags1' do
            knife('list --local -Rfp /data_bags').should_succeed(<<EOM, :stderr => "WARN: Child with name 'blah' found in multiple directories: #{Chef::Config.data_bag_path[0]}/blah and #{Chef::Config.data_bag_path[1]}/blah\n")
/data_bags/bag/
/data_bags/bag/item.json
/data_bags/bag2/
/data_bags/bag2/item2.json
/data_bags/blah/
/data_bags/blah/item1.json
EOM
          end
        end

        context 'when there is a directory in environments1 and file in environments2 with the same name' do
          directory 'environments/blah.json'
          file 'environments2/blah.json', {}
          it 'knife show /environments/blah.json succeeds' do
            pending "don't count directories in environments" do
              knife('show --local /environments/blah.json').should_succeed ''
            end
          end
        end

        context 'when there is a directory in nodes1 and file in nodes2 with the same name' do
          directory 'nodes/blah.json'
          file 'nodes2/blah.json', {}
          it 'knife show /nodes/blah.json succeeds' do
            pending "don't count directories in nodes" do
              knife('show --local /nodes/blah.json').should_succeed ''
            end
          end
        end

        context 'when there is a directory in roles1 and file in roles2 with the same name' do
          directory 'roles/blah.json'
          file 'roles2/blah.json', {}
          it 'knife show /roles/blah.json succeeds' do
            pending "don't count directories in roles" do
              knife('show --local /roles/blah.json').should_succeed ''
            end
          end
        end

        context 'when there is a directory in users1 and file in users2 with the same name' do
          directory 'users/blah.json'
          file 'users2/blah.json', {}
          it 'knife show /users/blah.json succeeds' do
            pending "don't count directories in users" do
              knife('show --local /users/blah.json').should_succeed ''
            end
          end
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag2/
bag2/item2.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag2/
data_bags/bag2/item2.json
environments/
environments/env1.json
environments/env2.json
roles/
roles/role1.json
roles/role2.json
EOM
          end
        end

        context 'when cwd is inside data_bags2' do
          cwd 'data_bags2'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag2/
bag2/item2.json
EOM
          end
        end
      end

      context 'when when chef_repo_path is set to both places and no other _path is set' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.chef_repo_path = [
            Chef::Config.chef_repo_path,
            File.join(Chef::Config.chef_repo_path, 'chef_repo2')
          ]
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
roles/
roles/role1.json
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
roles/
roles/role1.json
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when cookbook_path is set and nothing else' do
        before :each do
          %w(client data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.cookbook_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2', 'cookbooks')
          Chef::Config.chef_repo_path = nil
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env3.json
roles/
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when cookbook_path is set to multiple places and nothing else is set' do
        before :each do
          %w(client data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.cookbook_path = [
            File.join(Chef::Config.chef_repo_path, 'cookbooks'),
            File.join(Chef::Config.chef_repo_path, 'chef_repo2', 'cookbooks')
          ]
          Chef::Config.chef_repo_path = nil
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
roles/
roles/role1.json
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
roles/
roles/role1.json
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when data_bag_path and chef_repo_path are set, and nothing else' do
        before :each do
          %w(client cookbook  environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.data_bag_path = File.join(Chef::Config.chef_repo_path, 'data_bags')
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
cookbooks/
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
environments/
environments/env3.json
roles/
roles/role3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end
      end

      context 'when data_bag_path is set and nothing else' do
        before :each do
          %w(client cookbook  environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.data_bag_path = File.join(Chef::Config.chef_repo_path, 'data_bags')
          Chef::Config.chef_repo_path = nil
        end

        it 'knife list --local -Rfp / fails' do
          knife('list --local -Rfp /').should_fail("ERROR: Must specify either chef_repo_path or cookbook_path in Chef config file\n")
        end

        it 'knife list --local -Rfp /data_bags fails' do
          knife('list --local -Rfp /data_bags').should_fail("ERROR: Must specify either chef_repo_path or cookbook_path in Chef config file\n")
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Must specify either chef_repo_path or cookbook_path in Chef config file\n")
          end
        end
      end
    end

    when_the_repository 'is empty' do
      context 'when the repository _paths point to places that do not exist' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = File.join(Chef::Config.chef_repo_path, 'nowhere', object_name)
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'nowhere')
        end

        it 'knife list --local -Rfp / fails' do
          knife('list --local -Rfp /').should_succeed ''
        end

        it 'knife list --local -Rfp /data_bags fails' do
          knife('list --local -Rfp /data_bags').should_fail("ERROR: /data_bags: No such file or directory\n")
        end
      end
    end
  end
end
