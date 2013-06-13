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
        knife('list --local -Rfp /').should_succeed <<EOM
/data_bags/
EOM
      end
    end
  end

  when_the_repository 'has a cookbook starting with .' do
    file 'cookbooks/.svn/metadata.rb', ''
    file 'cookbooks/a.b/metadata.rb', ''
    it 'knife list does not show it' do
      knife('list --local -fp /cookbooks').should_succeed "/cookbooks/a.b/\n"
    end
  end

  when_the_repository 'has a data bag starting with .' do
    file 'data_bags/.svn/x.json', {}
    file 'data_bags/a.b/x.json', {}
    it 'knife list does not show it' do
      knife('list --local -fp /data_bags').should_succeed "/data_bags/a.b/\n"
    end
  end
end
