#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "chef/knife/cookbook_show"

describe "knife cookbook show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a cookbook" do
    before do
      cookbook "x", "1.0.0", { "recipes" => { "default.rb" => "file 'n'", "x.rb" => "" } }
      cookbook "x", "0.6.5"
    end

    it "knife cookbook show x shows all the versions" do
      knife("cookbook show x").should_succeed "x   1.0.0  0.6.5\n"
    end

    # rubocop:disable Layout/TrailingWhitespace
    it "knife cookbook show x 1.0.0 shows the correct version" do
      knife("cookbook show x 1.0.0").should_succeed <<~EOM
        cookbook_name: x
        frozen?:       false
        metadata:
          chef_versions:
          dependencies:
          description:
          eager_load_libraries: true
          gems:
          issues_url:
          license:              All rights reserved
          long_description:
          maintainer:
          maintainer_email:
          name:                 x
          ohai_versions:
          platforms:
          privacy:              false
          providing:
            x:    >= 0.0.0
            x::x: >= 0.0.0
          recipes:
            x:
            x::x:
          source_url:
          version:              1.0.0
        name:          x-1.0.0
        recipes:
          checksum:    4631b34cf58de10c5ef1304889941b2e
          name:        recipes/default.rb
          path:        recipes/default.rb
          specificity: default
          url:         http://127.0.0.1:8900/file_store/checksums/4631b34cf58de10c5ef1304889941b2e

          checksum:    d41d8cd98f00b204e9800998ecf8427e
          name:        recipes/x.rb
          path:        recipes/x.rb
          specificity: default
          url:         http://127.0.0.1:8900/file_store/checksums/d41d8cd98f00b204e9800998ecf8427e
        root_files:
          checksum:    8226671f751ba102dea6a6b6bd32fa8d
          name:        metadata.rb
          path:        metadata.rb
          specificity: default
          url:         http://127.0.0.1:8900/file_store/checksums/8226671f751ba102dea6a6b6bd32fa8d
        version:       1.0.0
      EOM
    end

    it "knife cookbook show x 1.0.0 metadata shows the metadata" do
      knife("cookbook show x 1.0.0 metadata").should_succeed <<~EOM
        chef_versions:
        dependencies:
        description:
        eager_load_libraries: true
        gems:
        issues_url:
        license:              All rights reserved
        long_description:
        maintainer:
        maintainer_email:
        name:                 x
        ohai_versions:
        platforms:
        privacy:              false
        providing:
          x:    >= 0.0.0
          x::x: >= 0.0.0
        recipes:
          x:
          x::x:
        source_url:
        version:              1.0.0
      EOM
    end

    it "knife cookbook show x 1.0.0 recipes shows all the recipes" do
      knife("cookbook show x 1.0.0 recipes").should_succeed <<~EOM
        checksum:    4631b34cf58de10c5ef1304889941b2e
        name:        recipes/default.rb
        path:        recipes/default.rb
        specificity: default
        url:         http://127.0.0.1:8900/file_store/checksums/4631b34cf58de10c5ef1304889941b2e

        checksum:    d41d8cd98f00b204e9800998ecf8427e
        name:        recipes/x.rb
        path:        recipes/x.rb
        specificity: default
        url:         http://127.0.0.1:8900/file_store/checksums/d41d8cd98f00b204e9800998ecf8427e
      EOM
    end
    # rubocop:enable Layout/TrailingWhitespace

    it "knife cookbook show x 1.0.0 recipes default.rb shows the default recipe" do
      knife("cookbook show x 1.0.0 recipes default.rb").should_succeed "file 'n'\n"
    end

    it "knife cookbook show with a non-existent file displays an error" do
      expect { knife("cookbook show x 1.0.0 recipes moose.rb") }.to raise_error(Chef::Exceptions::FileNotFound)
    end

    it "knife cookbook show with a non-existent version displays an error" do
      expect { knife("cookbook show x 1.0.1") }.to raise_error(Net::HTTPClientException)
    end

    it "knife cookbook show with a non-existent cookbook displays an error" do
      expect { knife("cookbook show y") }.to raise_error(Net::HTTPClientException)
    end
  end
end
