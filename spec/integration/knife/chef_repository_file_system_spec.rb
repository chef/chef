require 'support/shared/integration/integration_helper'
require 'chef/knife/list'

describe 'knife list' do
  extend IntegrationSupport
  include KnifeSupport

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
