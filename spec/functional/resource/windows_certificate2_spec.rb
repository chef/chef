# Author: Nimesh Patni (nimesh.patni@msystechnologies.com)
# Copyright:: Copyright (c) Chef Software Inc.
# License: Apache License, Version 2.0
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
require "chef/mixin/powershell_exec"
require "chef/resource/windows_certificate"

describe Chef::Resource::WindowsCertificate, :windows_only do
  include Chef::Mixin::PowershellExec

  def create_store(store_location: "LocalMachine", store_name: store)
    powershell_exec <<~EOC
      New-Item -Path Cert:\\#{store_location}\\#{store_name}
    EOC
  end

  def delete_store(store_location: "LocalMachine", store_name: store)
    powershell_exec <<~EOC
      Remove-Item -Path Cert:\\#{store_location}\\#{store_name} -Recurse
    EOC
  end

  def certificate_count(store_location: "LocalMachine", store_name: store)
    powershell_exec(<<~EOC).result.to_i
      (Get-ChildItem -Force -Path Cert:\\#{store_location}\\#{store_name} | measure).Count
    EOC
  end

  let(:password) { "P@ssw0rd!" }
  let(:store) { "Chef-Functional-Test" }
  # let(:store_name) { "MY" }
  let(:store_location) { "LocalMachine" }
  let(:download_cert_url) { "https://testingchef.blob.core.windows.net/files/test.cer?sv=2020-02-10&ss=b&srt=sco&sp=rlax&se=2022-03-20T01:20:15Z&st=2021-03-19T17:20:15Z&spr=https&sig=nMmvTTXp%2Fn0%2FYizBV8BzhjRJ%2Bmk%2BxYZ9529yOfqDxjQ%3D" }
  let(:cert_output_path) { ::File.join(Chef::Config[:file_cache_path], "output.cer") }
  let(:pfx_output_path) { ::File.join(Chef::Config[:file_cache_path], "output.pfx") }
  let(:key_output_path) { ::File.join(Chef::Config[:file_cache_path], "output.key") }
  let(:cer_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.cer") }
  let(:base64_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "base64_test.cer") }
  let(:pem_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.pem") }
  let(:p7b_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.p7b") }
  let(:pfx_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "test.pfx") }
  let(:tests_thumbprint) { "e45a4a7ff731e143cf20b8bfb9c7c4edd5238bb3" }
  let(:other_cer_path) { File.join(CHEF_SPEC_DATA, "windows_certificates", "othertest.cer") }
  let(:others_thumbprint) { "6eae1deefaf59daf1a97c9ceeff39c98b3da38cb" }
  let(:p7b_thumbprint) { "f867e25b928061318ed2c36ca517681774b06260" }
  let(:p7b_nested_thumbprint) { "dc395eae6be5b69951b8b6e1090cfc33df30d2cd" }

  let(:resource) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Chef::Resource::WindowsCertificate.new("ChefFunctionalTest", run_context).tap do |r|
      r.store_name = store
    end
  end

  before do
    # Bypass validation of the store name so we can use a fake test store.
    allow_any_instance_of(Chef::Mixin::ParamsValidate)
      .to receive(:_pv_equal_to)
      .with({ store_name: store }, :store_name, anything)
      .and_return(true)

      create_store

  end

  after { delete_store }

  describe "action: verify" do
    it "fails with no certificates in the store" do
      # expect(Chef::Log).to receive(:info).with("Certificate not found")

      # resource.source = tests_thumbprint
      # resource.run_action(:verify)

      # expect(resource).not_to be_updated_by_last_action
    end
  end

  describe "action: fetch" do
    # context "with no certificate in the store" do
    #   it "throws an error with no certificates in the store" do
    #     expect(Chef::Log).not_to receive(:info)
    #     resource.source = others_thumbprint
    #     resource.output_path = cert_output_path
    #     expect { resource.run_action :fetch }.to raise_error(ArgumentError)
    #   end
    # end

    # context "with a certificate in the store" do
    #   before do
    #     resource.source = cer_path
    #     resource.run_action(:create)
    #   end

    #   it "succeeds with a valid thumbprint" do
    #     resource.source = tests_thumbprint
    #     local_output_path = ::File.join(Chef::Config[:file_cache_path], "test.pem")
    #     resource.output_path = local_output_path
    #     resource.run_action(:fetch)
    #     expect(File.exist?(local_output_path)).to be_truthy
    #   end

    #   it "fails with an invalid thumbprint", :focus do
    #     expect(Chef::Log).not_to receive(:info)

    #     resource.source = others_thumbprint

    #     Dir.mktmpdir do |dir|
    #       path = File.join(dir, "test.pem")

    #       resource.output_path = path
    #       expect { resource.run_action :fetch }.to raise_error(ArgumentError)
    #     end
    #   end
    # end

    context "with a pfx/pkcs12 object in the store" do
      before do
        resource.source = pfx_path
        resource.pfx_password = password
        resource.exportable = true
        resource.run_action(:create)
      end

      # it "verfies" do
      #   resource.source = tests_thumbprint
      #   resource.run_action(:verify)
      # end

      it "exports a PFX file with a valid thumbprint", :focus do
        resource.source = tests_thumbprint
        resource.pfx_password = password
        resource.output_path = pfx_output_path
        resource.run_action(:fetch)
        expect(File.exist?(pfx_output_path)).to be_truthy
      end

      # it "exports a key file with a valid thumbprint" do
      #   resource.source = tests_thumbprint
      #   resource.pfx_password = password
      #   resource.output_path = key_output_path
      #   resource.run_action(:fetch)
      #   expect(File.exist?(key_output_path)).to be_truthy
      # end

      # it "throws an exception when output_path is not specified" do
      #   resource.source = tests_thumbprint
      #   resource.pfx_password = password
      #   expect { resource.run_action :fetch }.to raise_error(::Chef::Exceptions::ResourceNotFound)
      # end
    end
  end

end
