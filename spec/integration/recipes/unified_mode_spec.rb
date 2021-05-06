require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "Unified Mode" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.expand_path("../../..", __dir__) }

  let(:chef_client) { "bundle exec chef-client --minimal-ohai" }

  when_the_repository "has a cookbook with a unified_mode resource with a delayed notification from the second block to the first block" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode

          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              action :nothing
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              notifies :run, "ruby_block[first block]", :delayed
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the "second block" runs first after "bar" is set
      expect(result.stdout).to include("second: bar")
      # then the "first block" runs after "baz" in the delayed phase
      expect(result.stdout).to include("first: baz")
      # nothing else should fire
      expect(result.stdout).not_to include("first: foo")
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified_mode resource with a delayed notification from the first block to the second block" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode

          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              notifies :run, "ruby_block[second block]", :delayed
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              action :nothing
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default' -l debug", cwd: chef_dir)
      # the first block should fire first
      expect(result.stdout).to include("first: foo")
      # the second block should fire in delayed phase
      expect(result.stdout).to include("second: baz")
      # nothing else should fire
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("first: baz")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: bar")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified_mode resource with an immediate notification from the second block to the first block" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              action :nothing
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              notifies :run, "ruby_block[first block]", :immediate
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the second resource should fire first when it is parsed
      expect(result.stdout).to include("second: bar")
      # the first resource should then immediately fire
      expect(result.stdout).to include("first: bar")
      # no other resources should fire
      expect(result.stdout).not_to include("second: baz")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("first: foo")
      expect(result.stdout).not_to include("first: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified_mode resource with an immediate notification from the first block to the second block" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              notifies :run, "ruby_block[second block]", :immediate
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              action :nothing
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default' -l debug", cwd: chef_dir)
      # both blocks should run when they're declared
      expect(result.stdout).to include("first: foo")
      expect(result.stdout).to include("second: bar")
      # nothing else should run
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("first: baz")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified_mode resource with an immediate notification from the first block to a block that does not exist" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              notifies :run, "ruby_block[second block]", :immediate
            end
            var = "bar"
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should fail the run" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # both blocks should run when they're declared
      expect(result.stdout).to include("first: foo")
      # nothing else should run
      expect(result.stdout).not_to include("second: bar")
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("first: baz")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      expect(result.stdout).to include("Chef::Exceptions::ResourceNotFound")
      expect(result.error?).to be true
    end
  end

  when_the_repository "has a cookbook with a normal resource with an delayed notification with global resource unified mode on" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          resource_name :unified_mode
          provides :unified_mode

          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              action :nothing
            end
            var = "bar"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              notifies :run, "ruby_block[second block]", :delayed
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        resource_unified_mode_default true
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the "first block" resource runs before the assignment to baz in compile time
      expect(result.stdout).to include("first: bar")
      # we should not run the "first block" at compile time
      expect(result.stdout).not_to include("first: baz")
      # (and certainly should run it this early)
      expect(result.stdout).not_to include("first: foo")
      # the delayed notification should still fire and run after everything else
      expect(result.stdout).to include("second: baz")
      # the action :nothing should suppress any other running of the second block
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: bar")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a normal resource with an immediate notification with global resource unified mode on" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              action :nothing
            end
            var = "bar"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              notifies :run, "ruby_block[second block]", :immediate
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        resource_unified_mode_default true
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the "first block" resource runs before the assignment to baz in compile time
      expect(result.stdout).to include("first: bar")
      # we should not run the "first block" at compile time
      expect(result.stdout).not_to include("first: baz")
      # (and certainly should run it this early)
      expect(result.stdout).not_to include("first: foo")
      # the immediate notifiation fires immediately
      expect(result.stdout).to include("second: bar")
      # the action :nothing should suppress any other running of the second block
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with an immediate subscribes from the second resource to the first" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              subscribes :run, "ruby_block[first block]", :immediate
              action :nothing
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the first resource fires
      expect(result.stdout).to include("first: foo")
      # the second resource fires when it is parsed
      expect(result.stdout).to include("second: bar")
      # no other actions should run
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("first: baz")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with an immediate subscribes from the first resource to the second" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              subscribes :run, "ruby_block[second block]", :immediate
              action :nothing
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the second resource fires first after bar is set
      expect(result.stdout).to include("second: bar")
      # the first resource then has its immediate subscribes fire at that location
      expect(result.stdout).to include("first: bar")
      # no other actions should run
      expect(result.stdout).not_to include("first: baz")
      expect(result.stdout).not_to include("first: foo")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with an delayed subscribes from the second resource to the first" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
              subscribes :run, "ruby_block[first block]", :delayed
              action :nothing
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the first resource fires as it is parsed
      expect(result.stdout).to include("first: foo")
      # the second resource then fires in the delayed notifications phase
      expect(result.stdout).to include("second: baz")
      # no other actions should run
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("first: baz")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: bar")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with an delayed subscribes from the first resource to the second" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "first block" do
              block do
                puts "\nfirst: \#\{var\}"
              end
              subscribes :run, "ruby_block[second block]", :delayed
              action :nothing
            end
            var = "bar"
            ruby_block "second block" do
              block do
                puts "\nsecond: \#\{var\}"
              end
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # the second resource fires first after bar is set
      expect(result.stdout).to include("second: bar")
      # the first resource then fires in the delayed notifications phase
      expect(result.stdout).to include("first: baz")
      # no other actions should run
      expect(result.stdout).not_to include("first: foo")
      expect(result.stdout).not_to include("first: bar")
      expect(result.stdout).not_to include("second: foo")
      expect(result.stdout).not_to include("second: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with a correct before notification" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "notified block" do
              block do
                puts "\nnotified: \#\{var\}"
              end
              action :nothing
            end
            var = "bar"
            whyrun_safe_ruby_block "notifying block" do
              block do
                puts "\nnotifying: \#\{var\}"
              end
              notifies :run, "ruby_block[notified block]", :before
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      expect(result.stdout.scan(/notifying: bar/).length).to eql(2)
      expect(result.stdout).to include("Would execute the whyrun_safe_ruby_block notifying block")
      expect(result.stdout).to include("notified: bar")
      # no other actions should run
      expect(result.stdout).not_to include("notified: foo")
      expect(result.stdout).not_to include("notified: baz")
      expect(result.stdout).not_to include("notifying: foo")
      expect(result.stdout).not_to include("notifying: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with a correct before subscribes" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            ruby_block "notified block" do
              block do
                puts "\nnotified: \#\{var\}"
              end
              subscribes :run, "whyrun_safe_ruby_block[notifying block]", :before
              action :nothing
            end
            var = "bar"
            whyrun_safe_ruby_block "notifying block" do
              block do
                puts "\nnotifying: \#\{var\}"
              end
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      expect(result.stdout.scan(/notifying: bar/).length).to eql(2)
      expect(result.stdout).to include("Would execute the whyrun_safe_ruby_block notifying block")
      expect(result.stdout).to include("notified: bar")
      # no other actions should run
      expect(result.stdout).not_to include("notified: foo")
      expect(result.stdout).not_to include("notified: baz")
      expect(result.stdout).not_to include("notifying: foo")
      expect(result.stdout).not_to include("notifying: baz")
      result.error!
    end
  end

  when_the_repository "has a cookbook with a unified resource with a broken/reversed before notification" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            whyrun_safe_ruby_block "notifying block" do
              block do
                puts "\nnotifying: \#\{var\}"
              end
              notifies :run, "ruby_block[notified block]", :before
            end
            var = "bar"
            ruby_block "notified block" do
              block do
                puts "\nnotified: \#\{var\}"
              end
              action :nothing
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should fail the run" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default' -l debug", cwd: chef_dir)
      # this doesn't work and we can't tell the difference between it and if we were trying to do a correct :before notification but typo'd the name
      # so Chef::Exceptions::ResourceNotFound is the best we can do
      expect(result.stdout).to include("Chef::Exceptions::ResourceNotFound")
      expect(result.error?).to be true
    end
  end

  when_the_repository "has a cookbook with a unified resource with a broken/reversed before subscribes" do
    before do
      directory "cookbooks/x" do

        file "resources/unified_mode.rb", <<-EOM
          unified_mode true
          resource_name :unified_mode
          provides :unified_mode
          action :doit do
            klass = new_resource.class
            var = "foo"
            whyrun_safe_ruby_block "notifying block" do
              block do
                puts "\nnotifying: \#\{var\}"
              end
            end
            var = "bar"
            ruby_block "notified block" do
              block do
                puts "\nnotified: \#\{var\}"
              end
              subscribes :run, "whyrun_safe_ruby_block[notifying block]", :before
              action :nothing
            end
            var = "baz"
          end
        EOM

        file "recipes/default.rb", <<-EOM
          unified_mode "whatever"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should fail the run" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # this fires first normally before the error
      expect(result.stdout).to include("notifying: foo")
      # everything else does not run
      expect(result.stdout).not_to include("notified: foo")
      expect(result.stdout).not_to include("notified: bar")
      expect(result.stdout).not_to include("notified: baz")
      expect(result.stdout).not_to include("notifying: bar")
      expect(result.stdout).not_to include("notifying: baz")
      expect(result.stdout).to include("Chef::Exceptions::UnifiedModeBeforeSubscriptionEarlierResource")
      expect(result.error?).to be true
    end
  end

  when_the_repository "has global resource unified mode on" do
    before do
      directory "cookbooks/x" do

        file "recipes/default.rb", <<-EOM
          var = "foo"
          ruby_block "first block" do
            block do
              puts "\nfirst: \#\{var\}"
            end
          end
          var = "bar"
        EOM

      end # directory 'cookbooks/x'
    end

    it "recipes should still have a compile/converge mode" do
      file "config/client.rb", <<~EOM
        resource_unified_mode_default true
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # in recipe mode we should still run normally with a compile/converge mode
      expect(result.stdout).to include("first: bar")
      expect(result.stdout).not_to include("first: foo")
      result.error!
    end
  end

  when_the_repository "has a resource that uses edit_resource to create a subresource" do
    before do
      directory "cookbooks/x" do
        file "recipes/default.rb", <<~EOM
          my_resource "doit"
        EOM

        file "resources/my_resource.rb", <<~EOM
          unified_mode true
          provides :my_resource

          action :doit do
            edit_resource(:log, "name") do
              message "GOOD"
              level :warn
            end
          end
        EOM
      end
    end

    it "recipes should still have a compile/converge mode" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # in recipe mode we should still run normally with a compile/converge mode
      expect(result.stdout).to include("GOOD")
      result.error!
    end
  end

  when_the_repository "has a resource that uses find_resource to create a subresource" do
    before do
      directory "cookbooks/x" do
        file "recipes/default.rb", <<~EOM
          my_resource "doit"
        EOM

        file "resources/my_resource.rb", <<~EOM
          unified_mode true
          provides :my_resource

          action :doit do
            find_resource(:log, "name") do
              message "GOOD"
              level :warn
            end
          end
        EOM
      end
    end

    it "recipes should still have a compile/converge mode" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      # in recipe mode we should still run normally with a compile/converge mode
      expect(result.stdout).to include("GOOD")
      result.error!
    end
  end
end
