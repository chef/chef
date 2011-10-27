#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/shell_out'
require 'chef/mixin/shell_out'
require 'chef/index_queue/amqp_client'

include Chef::Mixin::ShellOut

CHEF_CLIENT = File.join(CHEF_PROJECT_ROOT, "chef", "bin", "chef-client")

def chef_client_command_string
  @log_level ||= ENV["LOG_LEVEL"] ? ENV["LOG_LEVEL"] : "error"
  @chef_args ||= ""
  @config_file ||= File.expand_path(File.join(configdir, 'client.rb'))

  "#{File.join(File.dirname(__FILE__), "..", "..", "chef", "bin", "chef-client")} -l #{@log_level} -c #{@config_file} #{@chef_args}"
end

###
# When
###
When /^I run the chef\-client$/ do
  status = Chef::Mixin::Command.popen4(chef_client_command_string()) do |p, i, o, e|
    @stdout = o.gets(nil)
    @stderr = e.gets(nil)
  end
  @status = status
end

When /^I run the chef\-client in the background with '(.+)'$/ do |args|
  @stdout_filename = "/tmp/chef.run_interval.stdout.#{$$}.txt"
  @stderr_filename = "/tmp/chef.run_interval.stderr.#{$$}.txt"

  @chef_args  = "#{args}"
  @client_pid = Process.fork do
    STDOUT.reopen(File.open(@stdout_filename, "w"))
    STDERR.reopen(File.open(@stderr_filename, "w"))
    exec chef_client_command_string()
    exit 2
  end
end

When /^I stop the background chef\-client after '(\d+)' seconds$/ do |timeout|
  begin
    sleep timeout.to_i
    Process.kill("KILL", @client_pid)
  rescue Errno::ESRCH
    # Kill didn't work; the process exited while we were waiting, like
    # it's supposed to.
  end

  # Read these in so they can be used in later steps.
  @stdout = IO.read(@stdout_filename)
  @stderr = IO.read(@stderr_filename)
end

Then /^the background chef\-client should not be running$/ do
  system("ps -af | grep #{@client_pid} | grep -vq grep")
  $?.exitstatus.should == 0
end

When "I run the chef-client for no more than '$timeout' seconds" do |timeout|
  cmd = shell_out("#{CHEF_CLIENT} -l info -i 1 -s 1 -c #{File.expand_path(File.join(configdir, 'client.rb'))}", :timeout => timeout.to_i)
  @status = cmd.status
end

When /^I run the chef\-client again$/ do
  When "I run the chef-client"
end

When /^I run the chef\-client with '(.+)'$/ do |args|
  @chef_args = args
  When "I run the chef-client"
end

When "I run the chef-client with '$options' and the '$config_file' config" do |options, config_file|
  @config_file = File.expand_path(File.join(configdir, "#{config_file}.rb"))
  @chef_args = options
  When "I run the chef-client"
end

When /^I run the chef\-client with '(.+)' for '(.+)' seconds$/ do |args, run_for|
  @chef_args = args
  When "I run the chef-client for '#{run_for}' seconds"
end

When /^I run the chef\-client for '(.+)' seconds$/ do |run_for|
  # Normal behavior depends on the run_interval/recipes/default.rb to count down
  # and exit subordinate chef-client after two runs. However, we will forcably
  # kill the client if that didn't work.
  begin
    stdout_filename = "/tmp/chef.run_interval.stdout.#{$$}.txt"
    stderr_filename = "/tmp/chef.run_interval.stderr.#{$$}.txt"
    client_pid = Process.fork do
      STDOUT.reopen(File.open(stdout_filename, "w"))
      STDERR.reopen(File.open(stderr_filename, "w"))
      exec chef_client_command_string()
      exit 2
    end

    killer_pid = Process.fork {
      sleep run_for.to_i

      # Send KILL to the child chef-client. Due to OHAI-223, where ohai sometimes
      # ignores/doesn't exit correctly on receipt of SIGINT, brutally kill the
      # subprocess.
      begin
        Process.kill("KILL", client_pid)
      rescue Errno::ESRCH
        # Kill didn't work; the process exited while we were waiting, like
        # it's supposed to.
      end
    }

    Process.waitpid2(killer_pid)
    @status = Process.waitpid2(client_pid).last

    # Read these in so they can be used in later steps.
    @stdout = IO.read(stdout_filename)
    @stderr = IO.read(stderr_filename)
  ensure
    # clean up after ourselves.
    File.delete(stdout_filename)
    File.delete(stderr_filename)
  end
end

When /^I run the chef\-client at log level '(.+)'$/ do |log_level|
  @log_level = log_level.to_sym
  When "I run the chef-client"
end

When 'I run the chef-client with json attributes' do
  @log_level = :debug
  @chef_args = "-j #{File.join(FEATURES_DATA, 'json_attribs', 'attribute_settings.json')}"
  When "I run the chef-client"
end

When "I run the chef-client with json attributes '$json_file_basename'" do |json_file_basename|
  @log_level = :debug
  @chef_args = "-j #{File.join(FEATURES_DATA, 'json_attribs', "#{json_file_basename}.json")}"
  When "I run the chef-client"
end

When /^I run the chef\-client with config file '(.+)'$/ do |config_file|
  @config_file = config_file
  When "I run the chef-client"
end

When /^I run the chef\-client with logging to the file '(.+)'$/ do |log_file|

config_data = <<CONFIG
supportdir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))

log_level        :debug
log_location     File.join(tmpdir, "silly-monkey.log")
file_cache_path  File.join(tmpdir, "cache")
ssl_verify_mode  :verify_none
registration_url "http://127.0.0.1:4000"
template_url     "http://127.0.0.1:4000"
remotefile_url   "http://127.0.0.1:4000"
search_url       "http://127.0.0.1:4000"
role_url         "http://127.0.0.1:4000"
client_url       "http://127.0.0.1:4000"
chef_server_url  "http://127.0.0.1:4000"
validation_client_name "validator"
systmpdir = File.expand_path(File.join(Dir.tmpdir, "chef_integration"))
validation_key   File.join(systmpdir, "validation.pem")
client_key       File.join(systmpdir, "client.pem")
CONFIG

  @config_file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'data', 'config', 'client-with-logging.rb'))
  File.open(@config_file, "w") do |file|
    file.write(config_data)
  end

  self.cleanup_files << @config_file


  @status = Chef::Mixin::Command.popen4("#{File.join(File.dirname(__FILE__), "..", "..", "chef", "bin", "chef-client")} -c #{@config_file} #{@chef_args}") do |p, i, o, e|
    @stdout = o.gets(nil)
    @stderr = e.gets(nil)
  end
end

When /^I update cookbook 'sync_library' from 'sync_library_updated' after the first run$/ do
  amqp  = Chef::IndexQueue::AmqpClient.instance
  queue = amqp.amqp_client.queue("sync_library_test")
  queue.subscribe(:timeout => 10) do |message|
    if "first run complete" == message[:payload]

      # Copy the updated library file over
      source = File.join(datadir, 'cookbooks', 'sync_library_updated')
      dest   = File.join(datadir, 'cookbooks', 'sync_library')
      cmd    = "cp -r #{source}/. #{dest}/."
      system(cmd)

      # Upload the updated cookbook
      knife_cmd = "#{KNIFE_CMD} cookbook upload -c #{KNIFE_CONFIG} -o #{INTEGRATION_COOKBOOKS} sync_library"
      shell_out!(knife_cmd)

      # Ack to release the client
      queue.delivery_tag = message[:delivery_details][:delivery_tag]
      queue.ack
      break
    end
  end
end

###
# Then
###
Then /^the run should exit '(.+)'$/ do |exit_code|
  if ENV['LOG_LEVEL'] == 'debug'
    puts @status.inspect
    puts @status.exitstatus
  end
  begin
    @status.exitstatus.should eql(exit_code.to_i)
  rescue
    print_output
    raise
  end
  print_output if ENV["LOG_LEVEL"] == "debug"
end

Then "I print the debug log" do
  print_output
end

Then /^the run should exit from being signaled$/ do
  begin
    @status.signaled?.should == true
  rescue
    print_output
    raise
  end
  print_output if ENV["LOG_LEVEL"] == "debug"
end


def print_output
  puts "--- run stdout:"
  puts @stdout
  puts "--- run stderr:"
  puts @stderr
end

# Matcher for regular expression which uses normal string interpolation for
# the actual (target) value instead of expecting it, as stdout/stderr which
# get matched against may have lots of newlines, which looks ugly when
# inspected, as the newlines show up as \n
class NoInspectMatch
  def initialize(expected_regex)
    @expected_regex = expected_regex
  end
  def matches?(target)
    @target = target
    @target =~ @expected_regex
  end
  def failure_message
    "expected #{@target} should match #{@expected_regex}"
  end
  def negative_failure_message
    "expected #{@target} not to match #{@expected_regex}"
  end
end
def noinspect_match(expected_regex)
  NoInspectMatch.new(expected_regex)
end


Then /^'(.+)' should have '(.+)'$/ do |which, to_match|
  if which == "stdout" || which == "stderr"
    self.instance_variable_get("@#{which}".to_sym).should noinspect_match(/#{to_match}/m)
  else
    self.instance_variable_get("@#{which}".to_sym).should match(/#{to_match}/m)
  end
end

Then /^'(.+)' should not have '(.+)'$/ do |which, to_match|
  to_match = Regexp.escape(to_match)
  if which == "stdout" || which == "stderr"
    self.instance_variable_get("@#{which}".to_sym).should_not noinspect_match(/#{to_match}/m)
  else
    self.instance_variable_get("@#{which}".to_sym).should_not match(/#{to_match}/m)
  end
end

Then /^'(.+)' should appear on '(.+)' '(.+)' times$/ do |to_match, which, count|
  seen_count = 0
  self.instance_variable_get("@#{which}".to_sym).split("\n").each do |line|
    seen_count += 1 if line =~ /#{to_match}/
  end
  seen_count.should == count.to_i
end

Then "I inspect the contents of the features tmpdir" do
  puts `ls -halpR #{tmpdir}`
end
