#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::Subversion do

  static_provider_resolution(
    resource: Chef::Resource::Subversion,
    provider: Chef::Provider::Subversion,
    name: :subversion,
    action: :install
  )

  before do
    @svn = Chef::Resource::Subversion.new("ohai, svn project!")
  end

  it "is a subclass of Resource::Scm" do
    expect(@svn).to be_an_instance_of(Chef::Resource::Subversion)
    expect(@svn).to be_a_kind_of(Chef::Resource::Scm)
  end

  it "allows the force_export action" do
    expect(@svn.allowed_actions).to include(:force_export)
  end

  it "sets svn info arguments to --no-auth-cache by default" do
    expect(@svn.svn_info_args).to eq("--no-auth-cache")
  end

  it "resets svn info arguments to nil when given false in the setter" do
    @svn.svn_info_args(false)
    expect(@svn.svn_info_args).to be_nil
  end

  it "sets svn arguments to --no-auth-cache by default" do
    expect(@svn.svn_arguments).to eq("--no-auth-cache")
  end

  it "sets svn binary to nil by default" do
    expect(@svn.svn_binary).to be_nil
  end

  it "resets svn arguments to nil when given false in the setter" do
    @svn.svn_arguments(false)
    expect(@svn.svn_arguments).to be_nil
  end

  it "hides password from custom exception message" do
    @svn.svn_password "l33th4x0rpa$$w0rd"
    e = @svn.customize_exception(Chef::Exceptions::Exec.new "Exception with password #{@svn.svn_password}")
    expect(e.message.include?(@svn.svn_password)).to be_falsey
  end
end
