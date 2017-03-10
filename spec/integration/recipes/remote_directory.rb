require "support/shared/integration/integration_helper"

describe Chef::Resource::RemoteDirectory do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  # Until Cheffish::RSpec has cookbook support, we have to run the whole client
  let(:chef_dir) { File.join(File.dirname(__FILE__), "..", "..", "..", "bin") }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "ruby '#{chef_dir}/chef-client' --minimal-ohai" }

  when_the_repository "has a cookbook with a source_dir with two subdirectories, each with one file and subdir in a different alphabetical order" do
    before do
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to('cookbooks')}"
      EOM
      directory "cookbooks/test" do
        directory "files/default/source_dir" do
          directory "sub1" do
            file "aaa", ""
            file "zzz/file", ""
          end
          directory "sub2" do
            file "aaa/file", ""
            file "zzz", ""
          end
        end
      end
    end

    context "and a recipe is run with a remote_directory that syncs source_dir with different mode and file_mode" do
      let!(:dest_dir) { path_to("dest_dir") }
      before do
        directory "cookbooks/test" do
          file "recipes/default.rb", <<-EOM
             remote_directory #{dest_dir.inspect} do
               source "source_dir"
               mode "0754"
               files_mode 0777
             end
          EOM
        end
        shell_out!("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'test::default'", :cwd => chef_dir)
      end

      def mode_of(path)
        path = path_to(path)
        stat = File.stat(path)
        (stat.mode & 0777).to_s(8)
      end

      it "creates all directories and files with the correct permissions" do
        expect(mode_of("dest_dir/sub1")).to eq "754"
        expect(mode_of("dest_dir/sub1/aaa")).to eq "777"
        expect(mode_of("dest_dir/sub1/zzz")).to eq "754"
        expect(mode_of("dest_dir/sub1/zzz/file")).to eq "777"
        expect(mode_of("dest_dir/sub2")).to eq "754"
        expect(mode_of("dest_dir/sub2/aaa")).to eq "754"
        expect(mode_of("dest_dir/sub2/aaa/file")).to eq "777"
        expect(mode_of("dest_dir/sub2/zzz")).to eq "777"
      end
    end
  end
end
