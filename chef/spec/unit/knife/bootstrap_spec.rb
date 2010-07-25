#
# Author:: Ian Meyer (<ianmmeyer@gmail.com>)
# Copyright:: Copyright (c) 2010 Ian Meyer
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::Bootstrap do
  before(:each) do
    @knife = Chef::Knife::Bootstrap.new
    @knife.config[:template_file] = File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test.erb"))
  end

  it "should load the default bootstrap template" do
    @knife.load_template.should be_a_kind_of(String)
  end

  it "should error if template can not be found" do
    @knife.config[:template_file] = false
    @knife.config[:distro] = 'penultimate'
    lambda { @knife.load_template }.should raise_error
  end

  it "should load the specified template" do
    @knife.config[:distro] = 'fedora13-gems'
    lambda { @knife.load_template }.should_not raise_error
  end

  it "should return an empty run_list" do
    template_string = @knife.load_template(@knife.config[:template_file])
    @knife.render_template(template_string).should == '{"run_list":[]}'
  end

  it "should have role[base] in the run_list" do
    template_string = @knife.load_template(@knife.config[:template_file])
    @knife.parse_options(["-r","role[base]"])
    @knife.render_template(template_string).should == '{"run_list":["role[base]"]}'
  end

  it "should have role[base] and recipe[cupcakes] in the run_list" do
    template_string = @knife.load_template(@knife.config[:template_file])
    @knife.parse_options(["-r", "role[base],recipe[cupcakes]"])
    @knife.render_template(template_string).should == '{"run_list":["role[base]","recipe[cupcakes]"]}'
  end

  it "should take the node name from ARGV" do
    @knife.name_args = ['barf']
    @knife.name_args.first.should == "barf"
  end

end
