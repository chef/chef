#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require_relative "scm"

describe Chef::Resource::Subversion do
  static_provider_resolution(
    resource: Chef::Resource::Subversion,
    provider: Chef::Provider::Subversion,
    name: :subversion,
    action: :install
  )

  let(:resource) { Chef::Resource::Subversion.new("fakey_fakerton") }

  it_behaves_like "an SCM resource"

  it "the destination property is the name_property" do
    expect(resource.destination).to eql("fakey_fakerton")
  end

  it "sets the default action as :sync" do
    expect(resource.action).to eql([:sync])
  end

  it "supports :checkout, :diff, :export, :force_export, :log, :sync actions" do
    expect { resource.action :checkout }.not_to raise_error
    expect { resource.action :diff }.not_to raise_error
    expect { resource.action :export }.not_to raise_error
    expect { resource.action :force_export }.not_to raise_error
    expect { resource.action :log }.not_to raise_error
    expect { resource.action :sync }.not_to raise_error
  end

  it "sets svn info arguments to --no-auth-cache by default" do
    expect(resource.svn_info_args).to eq("--no-auth-cache")
  end

  it "resets svn info arguments to nil when given false in the setter" do
    resource.svn_info_args(false)
    expect(resource.svn_info_args).to be_nil
  end

  it "sets svn arguments to --no-auth-cache by default" do
    expect(resource.svn_arguments).to eq("--no-auth-cache")
  end

  it "sets svn binary to nil by default" do
    expect(resource.svn_binary).to be_nil
  end

  it "resets svn arguments to nil when given false in the setter" do
    resource.svn_arguments(false)
    expect(resource.svn_arguments).to be_nil
  end

  it "has a svn_arguments String property" do
    expect(resource.svn_arguments).to eq("--no-auth-cache") # the default
    resource.svn_arguments "--more-taft plz"
    expect(resource.svn_arguments).to eql("--more-taft plz")
  end

  it "has a svn_info_args String property" do
    expect(resource.svn_info_args).to eq("--no-auth-cache") # the default
    resource.svn_info_args("--no-moar-plaintext-creds yep")
    expect(resource.svn_info_args).to eq("--no-moar-plaintext-creds yep")
  end

  it "hides password from custom exception message" do
    resource.svn_password "l33th4x0rpa$$w0rd"
    e = resource.customize_exception(Chef::Exceptions::Exec.new "Exception with password #{resource.svn_password}")
    expect(e.message.include?(resource.svn_password)).to be_falsey
  end
end
