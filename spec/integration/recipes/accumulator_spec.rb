require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "Accumulators" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.expand_path("../../..", __dir__) }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "bundle exec chef-client --minimal-ohai" }

  let(:aliases_temppath) do
    t = Tempfile.new("chef_accumulator_test")
    path = t.path
    t.close
    t.unlink
    path
  end

  when_the_repository "edit_resource-based delayed accumulators work" do
    before do
      directory "cookbooks/x" do
        file "resources/email_alias.rb", <<-EOM
          unified_mode true

          provides :email_alias
          resource_name :email_alias

          property :address, String, name_property: true, identity: true
          property :recipients, Array

          default_action :create

          action :create do
            with_run_context :root do
              edit_resource(:template, "#{aliases_temppath}") do |new_resource|
                source "aliases.erb"
                variables[:aliases] ||= {}
                variables[:aliases][new_resource.address] ||= []
                variables[:aliases][new_resource.address] += new_resource.recipients
                action :nothing
                delayed_action :create
              end
            end
          end
        EOM

        file "resources/nested.rb", <<-EOM
          unified_mode true

          provides :nested
          resource_name :nested

          property :address, String, name_property: true, identity: true
          property :recipients, Array

          default_action :create

          action :create do
            email_alias new_resource.address do
              recipients new_resource.recipients
            end
          end
        EOM

        file "resources/doubly_nested.rb", <<-EOM
          unified_mode true

          provides :doubly_nested
          resource_name :doubly_nested

          property :address, String, name_property: true, identity: true
          property :recipients, Array

          default_action :create

          action :create do
            nested new_resource.address do
              recipients new_resource.recipients
            end
          end
        EOM

        file "recipes/default.rb", <<-EOM
          email_alias "outer1" do
            recipients [ "out1a", "out1b" ]
          end

          nested "nested1" do
            recipients [ "nested1a", "nested1b" ]
          end

          email_alias "outer2" do
            recipients [ "out2a", "out2b" ]
          end

          doubly_nested "nested2" do
            recipients [ "nested2a", "nested2b" ]
          end

          email_alias "outer3" do
            recipients [ "out3a", "out3b" ]
          end
        EOM

        file "templates/aliases.erb", <<-EOM.gsub(/^\s+/, "")
          <%= pp @aliases %>
        EOM
      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      result.error!
      # runs only a single template resource (in the outer run context, as a delayed resource)
      expect(result.stdout.scan(/template\S+ action create/).size).to eql(1)
      # hash order is insertion order in ruby >= 1.9, so this next line does test that all calls were in the correct order
      expect(IO.read(aliases_temppath).chomp).to eql('{"outer1"=>["out1a", "out1b"], "nested1"=>["nested1a", "nested1b"], "outer2"=>["out2a", "out2b"], "nested2"=>["nested2a", "nested2b"], "outer3"=>["out3a", "out3b"]}')
    end
  end

  when_the_repository "find_resource-based delayed accumulators work" do
    before do
      directory "cookbooks/x" do
        file "resources/email_alias.rb", <<-EOM
          unified_mode true

          provides :email_alias
          resource_name :email_alias

          property :address, String, name_property: true, identity: true
          property :recipients, Array

          default_action :create

          action :create do
            r = with_run_context :root do
              find_resource(:template, "#{aliases_temppath}") do
                source "aliases.erb"
                variables[:aliases] = {}
                action :nothing
                delayed_action :create
              end
            end
            r.variables[:aliases][new_resource.address] ||= []
            r.variables[:aliases][new_resource.address] += new_resource.recipients
          end
        EOM

        file "resources/nested.rb", <<-EOM
          unified_mode true

          provides :nested
          resource_name :nested

          property :address, String, name_property: true, identity: true
          property :recipients, Array

          default_action :create

          action :create do
            email_alias new_resource.address do
              recipients new_resource.recipients
            end
          end
        EOM

        file "resources/doubly_nested.rb", <<-EOM
          unified_mode true

          provides :doubly_nested
          resource_name :doubly_nested

          property :address, String, name_property: true, identity: true
          property :recipients, Array

          default_action :create

          action :create do
            nested new_resource.address do
              recipients new_resource.recipients
            end
          end
        EOM

        file "recipes/default.rb", <<-EOM
          email_alias "outer1" do
            recipients [ "out1a", "out1b" ]
          end

          nested "nested1" do
            recipients [ "nested1a", "nested1b" ]
          end

          email_alias "outer2" do
            recipients [ "out2a", "out2b" ]
          end

          doubly_nested "nested2" do
            recipients [ "nested2a", "nested2b" ]
          end

          email_alias "outer3" do
            recipients [ "out3a", "out3b" ]
          end
        EOM

        file "templates/aliases.erb", <<-EOM.gsub(/^\s+/, "")
          <%= pp @aliases %>
        EOM
      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      result.error!
      # runs only a single template resource (in the outer run context, as a delayed resource)
      expect(result.stdout.scan(/template\S+ action create/).size).to eql(1)
      # hash order is insertion order in ruby >= 1.9, so this next line does test that all calls were in the correct order
      expect(IO.read(aliases_temppath).chomp).to eql('{"outer1"=>["out1a", "out1b"], "nested1"=>["nested1a", "nested1b"], "outer2"=>["out2a", "out2b"], "nested2"=>["nested2a", "nested2b"], "outer3"=>["out3a", "out3b"]}')
    end
  end
end
