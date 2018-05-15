require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "notifications" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.expand_path("../../../../bin", __FILE__) }
  let(:chef_client) { "ruby '#{chef_dir}/chef-client' --minimal-ohai" }

  when_the_repository "notifies a nameless resource" do
    before do
      directory "cookbooks/x" do
        file "recipes/default.rb", <<-EOM
          apt_update do
            action :nothing
          end
          log "foo" do
            notifies :nothing, 'apt_update', :delayed
          end
          log "bar" do
            notifies :nothing, 'apt_update[]', :delayed
          end
        EOM
      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      # our delayed notification should run at the end of the parent run_context after the baz resource
      expect(result.stdout).to match(/\* apt_update\[\] action nothing \(skipped due to action :nothing\)\s+\* log\[foo\] action write\s+\* log\[bar\] action write\s+\* apt_update\[\] action nothing \(skipped due to action :nothing\)/)
      result.error!
    end
  end

  when_the_repository "notifies delayed one" do
    before do
      directory "cookbooks/x" do

        file "resources/notifying_test.rb", <<EOM
default_action :run
provides :notifying_test
resource_name :notifying_test

action :run do
  log "bar" do
    notifies :write, 'log[foo]', :delayed
  end
end
EOM

        file "recipes/default.rb", <<EOM
log "foo" do
  action :nothing
end
notifying_test "whatever"
log "baz"
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      # our delayed notification should run at the end of the parent run_context after the baz resource
      expect(result.stdout).to match(/\* log\[bar\] action write\s+\* log\[baz\] action write\s+\* log\[foo\] action write/)
      result.error!
    end
  end

  when_the_repository "notifies delayed two" do
    before do
      directory "cookbooks/x" do

        file "resources/notifying_test.rb", <<EOM
default_action :run
provides :notifying_test
resource_name :notifying_test

action :run do
  log "bar" do
    notifies :write, 'log[foo]', :delayed
  end
end
EOM

        file "recipes/default.rb", <<EOM
log "foo" do
  action :nothing
end
notifying_test "whatever"
log "baz" do
  notifies :write, 'log[foo]', :delayed
end
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      # our delayed notification should run at the end of the parent run_context after the baz resource
      expect(result.stdout).to match(/\* log\[bar\] action write\s+\* log\[baz\] action write\s+\* log\[foo\] action write/)
      # and only run once
      expect(result.stdout).not_to match(/\* log\[foo\] action write.*\* log\[foo\] action write/)
      result.error!
    end
  end

  when_the_repository "notifies delayed three" do
    before do
      directory "cookbooks/x" do

        file "resources/notifying_test.rb", <<EOM
default_action :run
provides :notifying_test
resource_name :notifying_test

action :run do
  log "bar" do
    notifies :write, 'log[foo]', :delayed
  end
end
EOM

        file "recipes/default.rb", <<EOM
log "foo" do
  action :nothing
end
log "quux" do
  notifies :write, 'log[foo]', :delayed
  notifies :write, 'log[baz]', :delayed
end
notifying_test "whatever"
log "baz"
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      # the delayed notification from the sub-resource is de-duplicated by the notification already in the parent run_context
      expect(result.stdout).to match(/\* log\[quux\] action write\s+\* notifying_test\[whatever\] action run\s+\* log\[bar\] action write\s+\* log\[baz\] action write\s+\* log\[foo\] action write\s+\* log\[baz\] action write/)
      # and only run once
      expect(result.stdout).not_to match(/\* log\[foo\] action write.*\* log\[foo\] action write/)
      result.error!
    end
  end

  when_the_repository "notifies delayed four" do
    before do
      directory "cookbooks/x" do
        file "recipes/default.rb", <<EOM
log "foo" do
  action :nothing
end
log "bar" do
  notifies :write, 'log[foo]', :delayed
end
log "baz" do
  notifies :write, 'log[foo]', :delayed
end
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      # the delayed notification from the sub-resource is de-duplicated by the notification already in the parent run_context
      expect(result.stdout).to match(/\* log\[bar\] action write\s+\* log\[baz\] action write\s+\* log\[foo\] action write/)
      # and only run once
      expect(result.stdout).not_to match(/\* log\[foo\] action write.*\* log\[foo\] action write/)
      result.error!
    end
  end

  when_the_repository "notifies immediately" do
    before do
      directory "cookbooks/x" do

        file "resources/notifying_test.rb", <<EOM
default_action :run
provides :notifying_test
resource_name :notifying_test

action :run do
  log "bar" do
    notifies :write, 'log[foo]', :immediately
  end
end
EOM

        file "recipes/default.rb", <<EOM
log "foo" do
  action :nothing
end
notifying_test "whatever"
log "baz"
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      expect(result.stdout).to match(/\* log\[bar\] action write\s+\* log\[foo\] action write\s+\* log\[baz\] action write/)
      result.error!
    end
  end

  when_the_repository "uses old notifies syntax" do
    before do
      directory "cookbooks/x" do

        file "resources/notifying_test.rb", <<EOM
default_action :run
provides :notifying_test
resource_name :notifying_test

action :run do
  log "bar" do
    notifies :write, resources(log: "foo"), :immediately
  end
end
EOM

        file "recipes/default.rb", <<EOM
log "foo" do
  action :nothing
end
notifying_test "whatever"
log "baz"
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      expect(result.stdout).to match(/\* log\[bar\] action write\s+\* log\[foo\] action write\s+\* log\[baz\] action write/)
      result.error!
    end
  end

  when_the_repository "does not have a matching resource" do
    before do
      directory "cookbooks/x" do

        file "resources/notifying_test.rb", <<EOM
default_action :run
provides :notifying_test
resource_name :notifying_test

action :run do
  log "bar" do
    notifies :write, "log[foo]"
  end
end
EOM

        file "recipes/default.rb", <<EOM
notifying_test "whatever"
log "baz"
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      expect(result.stdout).to match(/Chef::Exceptions::ResourceNotFound/)
      expect(result.exitstatus).not_to eql(0)
    end
  end

  when_the_repository "encounters identical resources in parent and child resource collections" do
    before do
      directory "cookbooks/x" do

        file "resources/cloning_test.rb", <<EOM
default_action :run
provides :cloning_test
resource_name :cloning_test

action :run do
  log "bar" do
    level :info
  end
end
EOM

        file "recipes/default.rb", <<EOM
log "bar" do
  level :warn
end

cloning_test "whatever"
EOM

      end
    end

    it "should complete with success" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      expect(result.stdout).not_to match(/CHEF-3694/)
      result.error!
    end
  end

  when_the_repository "has resources that have arrays as the name" do
    before do
      directory "cookbooks/x" do
        file "recipes/default.rb", <<-EOM
          log [ "a", "b" ] do
            action :nothing
          end

          log "doit" do
            notifies :write, "log[a, b]"
          end
        EOM
      end
    end

    it "notifying the resource should work" do
      file "config/client.rb", <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      expect(result.stdout).to match /\* log\[a, b\] action write/
      result.error!
    end

  end
end
