require 'support/shared/integration/integration_helper'
require 'chef/knife/list'
require 'chef/knife/show'

describe 'chefignore tests' do
  extend IntegrationSupport
  include KnifeSupport

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
