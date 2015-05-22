#
# Author:: Daniel DeLeo (<dan@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
#

require 'spec_helper'

describe Chef::Formatters::Base do

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  subject(:formatter) { Chef::Formatters::Doc.new(out, err) }

  it "prints a policyfile's name and revision ID" do
    minimal_policyfile = {
      "revision_id"=> "613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073",
      "name"=> "jenkins",
      "run_list"=> [
        "recipe[apt::default]",
        "recipe[java::default]",
        "recipe[jenkins::master]",
        "recipe[policyfile_demo::default]"
      ],
      "cookbook_locks"=> { }
    }

    formatter.policyfile_loaded(minimal_policyfile)
    expect(out.string).to include("Using policy 'jenkins' at revision '613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073'")
  end

end
