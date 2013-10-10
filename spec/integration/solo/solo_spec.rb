require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'
require 'chef/run_lock'
require 'chef/config'
require 'timeout'
require 'fileutils'

describe "chef-solo" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  when_the_repository "has a cookbook with a no-op recipe" do
    file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
    file 'cookbooks/x/recipes/default.rb', ''

    it "should complete with success" do
      file 'config/solo.rb', <<EOM
cookbook_path "#{path_to('cookbooks')}"
file_cache_path "#{path_to('config/cache')}"
EOM
      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-solo -c \"#{path_to('config/solo.rb')}\" -o 'x::default' -l debug", :cwd => chef_dir)
      result.error!
    end
  end

  when_the_repository "has a cookbook with a recipe with sleep" do
    directory 'logs'
    file 'logs/runs.log', ''
    file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
    file 'cookbooks/x/recipes/default.rb', <<EOM
ruby_block "sleeping" do
  block do
    sleep 3
  end
end
EOM
    it "while running solo concurrently" do
      file 'config/solo.rb', <<EOM
cookbook_path "#{path_to('cookbooks')}"
file_cache_path "#{path_to('config/cache')}"
EOM
      # We have a timeout protection here so that if due to some bug
      # run_lock gets stuck we can discover it.
      lambda {
        Timeout.timeout(120) do
          chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")

          # Instantiate the first chef-solo run
          s1 = Process.spawn("chef-solo -c \"#{path_to('config/solo.rb')}\" -o 'x::default' \
-l debug -L #{path_to('logs/runs.log')}", :chdir => chef_dir)

          # Give it some time to progress
          sleep 3

          # Instantiate the second chef-solo run
          s2 = Process.spawn("chef-solo -c \"#{path_to('config/solo.rb')}\" -o 'x::default' \
-l debug -L #{path_to('logs/runs.log')}", :chdir => chef_dir)

          Process.waitpid(s1)
          Process.waitpid(s2)
        end
      }.should_not raise_error(Timeout::Error)

      # Unfortunately file / directory helpers in integration tests
      # are implemented using before(:each) so we need to do all below
      # checks in one example.
      run_log = File.read(path_to('logs/runs.log'))

      # both of the runs should succeed
      run_log.lines.reject {|l| !l.include? "INFO: Chef Run complete in"}.length.should == 2

      # second run should have a message which indicates it's waiting for the first run
      pid_lines = run_log.lines.reject {|l| !l.include? "Chef-client pid:"}
      pid_lines.length.should == 2
      pids = pid_lines.map {|l| l.split(" ").last}
      run_log.should include("Chef client #{pids[0]} is running, will wait for it to finish and then run.")

      # second run should start after first run ends
      starts = [ ]
      ends = [ ]
      run_log.lines.each_with_index do |line, index|
        if line.include? "Chef-client pid:"
          starts << index
        elsif line.include? "INFO: Chef Run complete in"
          ends << index
        end
      end
      starts[1].should > ends[0]
    end

  end
end
