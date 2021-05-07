#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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
#

require "spec_helper"
require "tiny_server"
require "support/shared/functional/http"

describe Chef::Resource::RemoteFile do
  include ChefHTTPShared

  let(:file_cache_path) { Dir.mktmpdir }

  before(:each) do
    @old_file_cache = Chef::Config[:file_cache_path]
    Chef::Config[:file_cache_path] = file_cache_path
    Chef::Config[:rest_timeout] = 2
    Chef::Config[:http_retry_delay] = 1
    Chef::Config[:http_retry_count] = 2
  end

  after(:each) do
    Chef::Config[:file_cache_path] = @old_file_cache
    FileUtils.rm_rf(file_cache_path)
  end

  include_context Chef::Resource::File

  let(:file_base) { "remote_file_spec" }

  def create_resource
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::RemoteFile.new(path, run_context)
    resource.source(source)
    resource
  end

  let(:resource) do
    create_resource
  end

  let(:default_mode) { (0666 & ~File.umask).to_s(8) }

  context "when fetching files over HTTP" do
    before(:all) do
      start_tiny_server(RequestTimeout: 1)
    end

    after(:all) do
      stop_tiny_server
    end

    describe "when redownload isn't necessary" do
      let(:source) { "http://localhost:9000/seattle_capo.png" }

      before do
        @api.get("/seattle_capo.png", 304, "", { "Etag" => "abcdef" } )
      end

      it "does not fetch the file" do
        resource.run_action(:create)
      end
    end

    context "when using normal encoding" do
      let(:source) { "http://localhost:9000/nyan_cat.png" }
      let(:expected_content) { binread(nyan_uncompressed_filename) }

      it_behaves_like "a file resource"

      it_behaves_like "a securable resource with reporting"
    end

    context "when using gzip encoding" do
      let(:source) { "http://localhost:9000/nyan_cat.png.gz" }
      let(:expected_content) { binread(nyan_compressed_filename) }

      it_behaves_like "a file resource"

      it_behaves_like "a securable resource with reporting"
    end

  end

  context "when fetching files over HTTPS" do

    before(:all) do
      cert_text = File.read(File.expand_path("ssl/chef-rspec.cert", CHEF_SPEC_DATA))
      cert = OpenSSL::X509::Certificate.new(cert_text)
      key_text = File.read(File.expand_path("ssl/chef-rspec.key", CHEF_SPEC_DATA))
      key = OpenSSL::PKey::RSA.new(key_text)

      server_opts = { SSLEnable: true,
                      SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
                      SSLCertificate: cert,
                      SSLPrivateKey: key,
                      RequestTimeout: 1 }

      start_tiny_server(**server_opts)
    end

    after(:all) do
      stop_tiny_server
    end

    let(:source) { "https://localhost:9000/nyan_cat.png" }

    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "a file resource"

  end

  context "when running on Windows", :windows_only do
    describe "when fetching files over SMB" do
      include Chef::Mixin::ShellOut
      let(:smb_share_root_directory) { directory = File.join(Dir.tmpdir, make_tmpname("windows_script_test")); Dir.mkdir(directory); directory }
      let(:smb_file_local_file_name) { "smb_file.txt" }
      let(:smb_file_local_path) { File.join( smb_share_root_directory, smb_file_local_file_name ) }
      let(:smb_share_name) { "chef_smb_test" }
      let(:smb_remote_path) { File.join("//#{ENV["COMPUTERNAME"]}", smb_share_name, smb_file_local_file_name).tr("/", "\\") }
      let(:smb_file_content) { "hellofun" }
      let(:local_destination_path) { File.join(Dir.tmpdir, make_tmpname("chef_remote_file")) }
      let(:windows_current_user) { ENV["USERNAME"] }
      let(:windows_current_user_domain) { ENV["USERDOMAIN"] || ENV["COMPUTERNAME"] }
      let(:windows_current_user_qualified) { "#{windows_current_user_domain}\\#{windows_current_user}" }

      let(:remote_domain) { nil }
      let(:remote_user) { nil }
      let(:remote_password) { nil }

      let(:resource) do
        node = Chef::Node.new
        events = Chef::EventDispatch::Dispatcher.new
        run_context = Chef::RunContext.new(node, {}, events)
        resource = Chef::Resource::RemoteFile.new(path, run_context)
      end

      before do
        shell_out("net.exe share #{smb_share_name} /delete")
        File.write(smb_file_local_path, smb_file_content )
        shell_out!("net.exe share #{smb_share_name}=\"#{smb_share_root_directory.tr("/", "\\")}\" /grant:\"authenticated users\",read")
      end

      after do
        shell_out("net.exe share #{smb_share_name} /delete")
        File.delete(smb_file_local_path) if File.exist?(smb_file_local_path)
        File.delete(local_destination_path) if File.exist?(local_destination_path)
        Dir.rmdir(smb_share_root_directory)
      end

      context "when configuring the Windows identity used to access the remote file" do
        before do
          resource.path(local_destination_path)
          resource.source(smb_remote_path)
          resource.remote_domain(remote_domain)
          resource.remote_user(remote_user)
          resource.remote_password(remote_password)
          resource.node.default["platform_family"] = "windows"
          allow_any_instance_of(Chef::Provider::RemoteFile::NetworkFile).to receive(:node).and_return({ "platform_family" => "windows" })
        end

        shared_examples_for "a remote_file resource accessing a remote file to which the specified user has access" do
          it "has the same content as the original file" do
            expect { resource.run_action(:create) }.not_to raise_error
            expect(::File.read(local_destination_path).chomp).to eq smb_file_content
          end
        end

        shared_examples_for "a remote_file resource accessing a remote file to which the specified user does not have access" do
          it "causes an error to be raised" do
            expect { resource.run_action(:create) }.to raise_error(Errno::EACCES)
          end
        end

        shared_examples_for "a remote_file resource accessing a remote file with invalid user" do
          it "causes an error to be raised" do
            allow(Chef::Util::Windows::LogonSession).to receive(:validate_session_open!).and_return(true)
            expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::Win32APIError)
          end
        end

        context "when the file is accessible to non-admin users only as the current identity" do
          before do
            shell_out!("icacls #{smb_file_local_path} /grant:r \"authenticated users:(W)\" /grant \"#{windows_current_user_qualified}:(R)\" /inheritance:r")
          end

          context "when the resource is accessed using the current user's identity" do
            let(:remote_user) { nil }
            let(:remote_domain) { nil }
            let(:remote_password) { nil }

            it_behaves_like "a remote_file resource accessing a remote file to which the specified user has access"

            describe "uses the ::Chef::Provider::RemoteFile::NetworkFile::TRANSFER_CHUNK_SIZE constant to chunk the file" do
              let(:invalid_chunk_size) { -1 }
              before do
                stub_const("::Chef::Provider::RemoteFile::NetworkFile::TRANSFER_CHUNK_SIZE", invalid_chunk_size)
              end

              it "raises an ArgumentError when the chunk size is negative" do
                expect(::Chef::Provider::RemoteFile::NetworkFile::TRANSFER_CHUNK_SIZE).to eq(invalid_chunk_size)
                expect { resource.run_action(:create) }.to raise_error(ArgumentError)
              end
            end

            context "when the file must be transferred in more than one chunk" do
              before do
                stub_const("::Chef::Provider::RemoteFile::NetworkFile::TRANSFER_CHUNK_SIZE", 3)
              end
              it_behaves_like "a remote_file resource accessing a remote file to which the specified user has access"
            end
          end

          context "when the resource is accessed using an alternate user's identity with no access to the file" do
            let(:windows_nonadmin_user) { "chefremfile1" }
            let(:windows_nonadmin_user_password) { "j82ajfxK3;2Xe1" }
            include_context "a non-admin Windows user"

            before do
              shell_out!("icacls #{smb_file_local_path} /grant:r \"authenticated users:(W)\" /deny \"#{windows_current_user_qualified}:(R)\" /inheritance:r")
            end

            let(:remote_user) { windows_nonadmin_user }
            let(:remote_domain) { windows_nonadmin_user_domain }
            let(:remote_password) { windows_nonadmin_user_password }

            it_behaves_like "a remote_file resource accessing a remote file to which the specified user does not have access"
          end
        end

        context "when the the file is only accessible as a specific alternate identity" do
          let(:windows_nonadmin_user) { "chefremfile2" }
          let(:windows_nonadmin_user_password) { "j82ajfxK3;2Xe2" }
          include_context "a non-admin Windows user"

          before do
            shell_out!("icacls #{smb_file_local_path} /grant:r \"authenticated users:(W)\" /grant \"#{windows_current_user_qualified}:(R)\" /inheritance:r")
          end

          context "when the resource is accessed using the specific non-qualified alternate user identity with access" do
            let(:remote_user) { windows_nonadmin_user }
            let(:remote_domain) { "." }
            let(:remote_password) { windows_nonadmin_user_password }

            it_behaves_like "a remote_file resource accessing a remote file to which the specified user has access"
          end

          context "when the resource is accessed using the specific alternate user identity with access and the domain is specified" do
            let(:remote_user) { windows_nonadmin_user }
            let(:remote_domain) { windows_nonadmin_user_domain }
            let(:remote_password) { windows_nonadmin_user_password }

            it_behaves_like "a remote_file resource accessing a remote file to which the specified user has access"
          end

          context "when the resource is accessed using the current user's identity" do
            before do
              shell_out!("icacls #{smb_file_local_path} /grant:r \"authenticated users:(W)\" /grant \"#{windows_nonadmin_user_qualified}:(R)\" /deny #{windows_current_user_qualified}:(R) /inheritance:r")
            end

            it_behaves_like "a remote_file resource accessing a remote file to which the specified user does not have access"
          end

          context "when the resource is accessed using an alternate user's identity with no access to the file" do
            let(:windows_nonadmin_user) { "chefremfile3" }
            let(:windows_nonadmin_user_password) { "j82ajfxK3;2Xe3" }
            include_context "a non-admin Windows user"

            let(:remote_user) { windows_nonadmin_user_qualified }
            let(:remote_domain) { nil }
            let(:remote_password) { windows_nonadmin_user_password }

            before do
              allow_any_instance_of(Chef::Util::Windows::LogonSession).to receive(:validate_session_open!).and_return(true)
            end

            it_behaves_like "a remote_file resource accessing a remote file with invalid user"
          end
        end
      end
    end
  end

  context "when dealing with content length checking" do
    before(:all) do
      start_tiny_server(RequestTimeout: 1)
    end

    after(:all) do
      stop_tiny_server
    end

    context "when downloading compressed data" do
      let(:expected_content) { binread(nyan_uncompressed_filename) }
      let(:source) { "http://localhost:9000/nyan_cat_content_length_compressed.png" }

      before do
        expect(File).not_to exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        expect(File).to exist(path)
      end

      it "should mark the resource as updated" do
        expect(resource).to be_updated_by_last_action
      end

      it "has the correct content" do
        expect(binread(path)).to eq(expected_content)
      end
    end

    context "when downloding uncompressed data" do
      let(:expected_content) { binread(nyan_uncompressed_filename) }
      let(:source) { "http://localhost:9000/nyan_cat_content_length.png" }

      before do
        expect(File).not_to exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        expect(File).to exist(path)
      end

      it "should mark the resource as updated" do
        expect(resource).to be_updated_by_last_action
      end

      it "has the correct content" do
        expect(binread(path)).to eq(expected_content)
      end
    end

    context "when downloading truncated compressed data" do
      let(:source) { "http://localhost:9000/nyan_cat_truncated_compressed.png" }

      before do
        expect(File).not_to exist(path)
      end

      it "should raise ContentLengthMismatch" do
        expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
        # File.should_not exist(path) # XXX: CHEF-5081
      end
    end

    context "when downloding truncated uncompressed data" do
      let(:source) { "http://localhost:9000/nyan_cat_truncated.png" }

      before do
        expect(File).not_to exist(path)
      end

      it "should raise ContentLengthMismatch" do
        expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
        # File.should_not exist(path) # XXX: CHEF-5081
      end
    end

    context "when downloding data with transfer-encoding set" do
      let(:expected_content) { binread(nyan_uncompressed_filename) }
      let(:source) { "http://localhost:9000/nyan_cat_transfer_encoding.png" }

      before do
        expect(File).not_to exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        expect(File).to exist(path)
      end

      it "should mark the resource as updated" do
        expect(resource).to be_updated_by_last_action
      end

      it "has the correct content" do
        expect(binread(path)).to eq(expected_content)
      end
    end

    describe "when the download of the source raises an exception" do
      let(:source) { "http://localhost:0000/seattle_capo.png" }

      before do
        expect(File).not_to exist(path)
      end

      it "should not create the file" do
        # This can legitimately raise either Errno::EADDRNOTAVAIL or Errno::ECONNREFUSED
        # in different Ruby versions.
        expect { resource.run_action(:create) }.to raise_error(SystemCallError)

        expect(File).not_to exist(path)
      end
    end
  end
end
