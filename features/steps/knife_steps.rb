When "I upload the '$cookbook_name' cookbook with knife" do |cookbook_name|
  cookbook_fixture = File.join(FEATURES_DATA, "cookbooks_not_uploaded_at_feature_start", cookbook_name)
  cookbook_dir = ::Tempfile.open("knife-cuke-cookbook-dir").path
  FileUtils.rm(cookbook_dir)
  FileUtils.mkdir_p(cookbook_dir)
  FileUtils.cp_r(cookbook_fixture, cookbook_dir)
  shell_out!("#{KNIFE_CMD} cookbook upload #{cookbook_name} -o #{cookbook_dir} -c #{KNIFE_CONFIG}")
end

When "I run knife '$knife_subcommand'" do |knife_subcommand|
  @knife_command_result = shell_out("#{KNIFE_CMD} #{knife_subcommand} -c #{KNIFE_CONFIG}")
end

RSpec::Matchers.define :be_successful do
  match do |shell_out_result|
    shell_out_result.status.success?
  end
  failure_message_for_should do |shell_out_result|
    "Expected command #{shell_out_result.command} to exit successfully, but it exited with status #{shell_out_result.exitstatus}.\n"\
    "STDOUT OUTPUT:\n#{shell_out_result.stdout}\nSTDERR OUTPUT:\n#{shell_out_result.stderr}\n"
  end
  failure_message_for_should_not do |shell_out_result|
    "Expected command #{shell_out_result.command} to fail, but it exited with status #{shell_out_result.exitstatus}.\n"\
    "STDOUT OUTPUT:\n#{shell_out_result.stdout}\nSTDERR OUTPUT:\n#{shell_out_result.stderr}\n"
  end
  description do
    "The shell out command should exit 0"
  end
end

Then /^knife should succeed$/ do
  @knife_command_result.should be_successful
end
