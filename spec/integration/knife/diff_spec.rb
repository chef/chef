require 'support/shared/integration/integration_helper'
require 'chef/knife/diff'

describe 'knife diff' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server "has one of each thing" do
    one_of_each_resource_in_chef_server

    when_the_repository 'has only top-level directories' do
      directory 'clients'
      directory 'cookbooks'
      directory 'data_bags'
      directory 'environments'
      directory 'nodes'
      directory 'roles'
      directory 'users'

      without_versioned_cookbooks do
        it 'knife diff reports everything as deleted' do
          knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks/x
D\t/data_bags/x
D\t/environments/_default.json
D\t/environments/x.json
D\t/roles/x.json
EOM
        end
      end # without versioned cookbooks

      with_versioned_cookbooks do
        it 'knife diff reports everything as deleted' do
          knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks/x-1.0.0
D\t/data_bags/x
D\t/environments/_default.json
D\t/environments/x.json
D\t/roles/x.json
EOM
        end
      end # with versioned cookbooks
    end

    when_the_repository 'has an identical copy of each resource' do
      with_all_types_of_repository_layouts do
        one_of_each_resource_in_repository

        it 'knife diff reports no differences' do
          knife('diff /').should_succeed ''
        end

        it 'knife diff /environments/nonexistent.json reports an error' do
          knife('diff /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory on remote or local\n"
        end

        it 'knife diff /environments/*.txt reports an error' do
          knife('diff /environments/*.txt').should_fail "ERROR: /environments/*.txt: No such file or directory on remote or local\n"
        end
      end # with all types of repository layouts
    end # when the repository has an identical copy of each resource

    when_the_repository 'has a different role file' do
      with_all_types_of_repository_layouts do
        one_of_each_resource_in_repository
        file 'roles/x.json', <<EOM
{
  "foo": "bar"
}
EOM
        it 'knife diff reports the role as different' do
          knife('diff --name-status /').should_succeed <<EOM
M\t/roles/x.json
EOM
        end
      end # with all types of repository layouts
    end # when the repository has a different role file

    when_the_repository 'has resources not present in the server' do
      file 'clients/y.json', {}
      file 'data_bags/x/z.json', {}
      file 'data_bags/y/zz.json', {}
      file 'environments/y.json', {}
      file 'nodes/y.json', {}
      file 'roles/y.json', {}
      file 'users/y.json', {}

      without_versioned_cookbooks do
        one_of_each_resource_in_repository
        file 'cookbooks/x/blah.rb', ''
        file 'cookbooks/y/metadata.rb', 'version "1.0.0"'

        it 'knife diff reports the new files as added' do
          knife('diff --name-status /').should_succeed <<EOM
A\t/cookbooks/x/blah.rb
A\t/cookbooks/y
A\t/data_bags/x/z.json
A\t/data_bags/y
A\t/environments/y.json
A\t/roles/y.json
EOM
        end

        context 'when cwd is the data_bags directory' do
          cwd 'data_bags'
          it 'knife diff reports different data bags' do
            knife('diff --name-status').should_succeed <<EOM
A\tx/z.json
A\ty
EOM
            end
          it 'knife diff * reports different data bags' do
            knife('diff --name-status *').should_succeed <<EOM
A\tx/z.json
A\ty
EOM
          end
        end # when cwd is the data_bags directory
      end # without versioned cookbooks

      with_versioned_cookbooks do
        one_of_each_resource_in_repository
        file 'cookbooks/x-1.0.0/blah.rb', ''
        file 'cookbooks/y-1.0.0/metadata.rb', ['name "y"', 'version "1.0.0"'].join("\n")

        it 'knife diff reports the new files as added' do
          knife('diff --name-status /').should_succeed <<EOM
A\t/cookbooks/x-1.0.0/blah.rb
A\t/cookbooks/y-1.0.0
A\t/data_bags/x/z.json
A\t/data_bags/y
A\t/environments/y.json
A\t/roles/y.json
EOM
        end

        context 'when cwd is the data_bags directory' do
          cwd 'data_bags'
          it 'knife diff reports different data bags' do
            knife('diff --name-status').should_succeed <<EOM
A\tx/z.json
A\ty
EOM
            end
          it 'knife diff * reports different data bags' do
            knife('diff --name-status *').should_succeed <<EOM
A\tx/z.json
A\ty
EOM
          end
        end # when cwd is the data_bags directory
      end # with versioned cookbooks
    end # when the repository has resources not present in the server

    when_the_repository 'is empty' do
      it 'knife diff reports everything as deleted' do
        knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/roles
EOM
      end
    end
  end

  when_the_repository 'has a cookbook' do
    # TODO: make this DSL lazy-eval so we don't have to do stuff like this
    def self.repository_has_a_cookbook
      if metadata[:versioned_cookbooks]
        file 'cookbooks/x-1.0.0/metadata.rb', ['name "x"', 'version "1.0.0"']
        file 'cookbooks/x-1.0.0/onlyin1.0.0.rb', ''
      else
        file 'cookbooks/x/metadata.rb', ['name "x"', 'version "1.0.0"']
        file 'cookbooks/x/onlyin1.0.0.rb', ''
      end
    end

    when_the_chef_server 'has a later version for the cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => ['name "x"', 'version "1.0.0"'].join("\n"), 'onlyin1.0.0.rb' => ''}
      cookbook 'x', '1.0.1', { 'metadata.rb' => ['name "x"', 'version "1.0.1"'].join("\n"), 'onlyin1.0.1.rb' => '' }

      without_versioned_cookbooks do
        repository_has_a_cookbook

        it 'knife diff /cookbooks/x shows differences' do
          knife('diff --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
        end

        it 'knife diff --diff-filter=MAT does not show deleted files' do
          knife('diff --diff-filter=MAT --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
        end
      end # without versioned cookbooks

      with_versioned_cookbooks do
        repository_has_a_cookbook

        it 'knife diff /cookbooks shows differences' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x-1.0.1
EOM
        end

        it 'knife diff --diff-filter=MAT does not show deleted files' do
          # No difference
          knife('diff --diff-filter=MAT --name-status /cookbooks').should_succeed ''
        end
      end # withversioned cookbooks
    end # when the chef server has a later version for the cookbook

    when_the_chef_server 'has an earlier version for the cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => ['name "x"', 'version "1.0.0"'].join("\n"), 'onlyin1.0.0.rb' => '' }
      cookbook 'x', '0.9.9', { 'metadata.rb' => ['name "x"', 'version "0.9.9"'].join("\n"), 'onlyin0.9.9.rb' => '' }

      without_versioned_cookbooks do
        repository_has_a_cookbook
        it 'knife diff /cookbooks/x shows no differences' do
          knife('diff --name-status /cookbooks/x').should_succeed ''
        end
      end

      with_versioned_cookbooks do
        repository_has_a_cookbook
        it 'knife diff /cookbooks shows no differences' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x-0.9.9
EOM
        end
      end
    end

    when_the_chef_server 'has a later version for the cookbook, and no current version' do
      cookbook 'x', '1.0.1', { 'metadata.rb' => ['name "x"', 'version "1.0.1"'].join("\n"), 'onlyin1.0.1.rb' => '' }

      without_versioned_cookbooks do
        repository_has_a_cookbook
        it 'knife diff /cookbooks/x shows the differences' do
          knife('diff --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
        end
      end

      with_versioned_cookbooks do
        repository_has_a_cookbook
        it 'knife diff /cookbooks shows the differences' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x-1.0.1
A\t/cookbooks/x-1.0.0
EOM
        end
      end
    end

    when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
      cookbook 'x', '0.9.9', { 'metadata.rb' => ['name "x"', 'version "0.9.9"'].join("\n"), 'onlyin0.9.9.rb' => '' }

      without_versioned_cookbooks do
        repository_has_a_cookbook

        it 'knife diff /cookbooks/x shows the differences' do
          knife('diff --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin0.9.9.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
        end
      end

      with_versioned_cookbooks do
        repository_has_a_cookbook

        it 'knife diff /cookbooks shows the differences' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x-0.9.9
A\t/cookbooks/x-1.0.0
EOM
        end
      end
    end # when the chef server has an earlier version for the cookbook and no current version
  end

  context 'json diff tests' do
    when_the_repository 'has an empty environment file' do
      file 'environments/x.json', {}
      when_the_chef_server 'has an empty environment' do
        environment 'x', {}
        it 'knife diff returns no differences' do
          knife('diff /environments/x.json').should_succeed ''
        end
      end
      when_the_chef_server 'has an environment with a different value' do
        environment 'x', { 'description' => 'hi' }
        it 'knife diff reports the difference', :pending => (RUBY_VERSION < "1.9") do
          knife('diff /environments/x.json').should_succeed(/
 {
-  "name": "x",
-  "description": "hi"
\+  "name": "x"
 }
/)
        end
      end
    end

    when_the_repository 'has an environment file with a value in it' do
      file 'environments/x.json', { 'description' => 'hi' }
      when_the_chef_server 'has an environment with the same value' do
        environment 'x', { 'description' => 'hi' }
        it 'knife diff returns no differences' do
          knife('diff /environments/x.json').should_succeed ''
        end
      end
      when_the_chef_server 'has an environment with no value' do
        environment 'x', {}
        it 'knife diff reports the difference', :pending => (RUBY_VERSION < "1.9") do
          knife('diff /environments/x.json').should_succeed(/
 {
-  "name": "x"
\+  "name": "x",
\+  "description": "hi"
 }
/)
        end
      end
      when_the_chef_server 'has an environment with a different value' do
        environment 'x', { 'description' => 'lo' }
        it 'knife diff reports the difference', :pending => (RUBY_VERSION < "1.9") do
          knife('diff /environments/x.json').should_succeed(/
 {
   "name": "x",
-  "description": "lo"
\+  "description": "hi"
 }
/)
        end
      end
    end
  end

  when_the_chef_server 'has an environment' do
    environment 'x', {}
    when_the_repository 'has an environment with bad JSON' do
      file 'environments/x.json', '{'
      it 'knife diff reports an error and does a textual diff' do
        knife('diff /environments/x.json').should_succeed(/-  "name": "x"/, :stderr => "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\n")
      end
    end
  end
end
