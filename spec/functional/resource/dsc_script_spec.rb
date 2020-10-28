#
# Author:: Adam Edwards (<adamed@chef.io>)
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
require "chef/mixin/powershell_exec"
require "chef/mixin/windows_architecture_helper"
require "support/shared/integration/integration_helper"

describe Chef::Resource::DscScript, :windows_powershell_dsc_only do
  include Chef::Mixin::WindowsArchitectureHelper
  include Chef::Mixin::PowershellExec
  before(:all) do
    @temp_dir = ::Dir.mktmpdir("dsc-functional-test")
    # enable the HTTP listener if it is not already enabled needed by underlying DSC engine
    winrm_code = <<-CODE
      winrm get winrm/config/listener?Address=*+Transport=HTTP
      if($LASTEXITCODE -ne 0) {
        winrm create winrm/config/Listener?Address=*+Transport=HTTP
      }
    CODE
    powershell_exec!(winrm_code)
  end

  after(:all) do
    ::FileUtils.rm_rf(@temp_dir) if ::Dir.exist?(@temp_dir)
  end

  include Chef::Mixin::ShellOut

  def create_config_script_from_code(code, configuration_name, data = false)
    script_code = data ? code : "Configuration '#{configuration_name}'\n{\n\t#{code}\n}\n"
    data_suffix = data ? "_config_data" : ""
    extension = data ? "psd1" : "ps1"
    script_path = "#{@temp_dir}/dsc_functional_test#{data_suffix}.#{extension}"
    ::File.open(script_path, "wt") do |script|
      script.write(script_code)
    end
    script_path
  end

  def user_exists?(target_user)
    result = false
    begin
      shell_out!("net user #{target_user}")
      result = true
    rescue Mixlib::ShellOut::ShellCommandFailed
    end
    result
  end

  def delete_user(target_user)
    shell_out!("net user #{target_user} /delete")
  rescue Mixlib::ShellOut::ShellCommandFailed
  end

  let(:dsc_env_variable) { "chefenvtest" }
  let(:dsc_env_value1) { "value1" }
  let(:env_value2) { "value2" }
  let(:dsc_test_run_context) do
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data, {}) # node[:languages][:powershell][:version]
    node.automatic["os"] = "windows"
    node.automatic["platform"] = "windows"
    node.automatic["platform_version"] = "6.1"
    node.automatic["kernel"][:machine] = :x86_64 # Only 64-bit architecture is supported
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end
  let(:dsc_test_resource_name) { "DSCTest" }
  let(:dsc_test_resource_base) do
    Chef::Resource::DscScript.new(dsc_test_resource_name, dsc_test_run_context)
  end
  let(:test_registry_key) { 'HKEY_LOCAL_MACHINE\Software\Chef\Spec\Functional\Resource\dsc_script_spec' }
  let(:test_registry_value) { "Registration" }
  let(:test_registry_data1) { "LL927" }
  let(:test_registry_data2) { "LL928" }
  let(:reg_key_name_param_name) { "testregkeyname" }
  let(:reg_key_value_param_name) { "testregvaluename" }
  let(:registry_embedded_parameters) { "$#{reg_key_name_param_name} = '#{test_registry_key}';$#{reg_key_value_param_name} = '#{test_registry_value}'" }
  let(:dsc_reg_code) do
    <<-EOH
  #{registry_embedded_parameters}
  Registry "ChefRegKey"
  {
     Key = $#{reg_key_name_param_name}
     ValueName = $#{reg_key_value_param_name}
     ValueData = '#{test_registry_data}'
     Ensure = 'Present'
  }
    EOH
  end

  let(:dsc_code) { dsc_reg_code }
  let(:dsc_reg_script) do
    <<-EOH
  param($testregkeyname, $testregvaluename)
  #{dsc_reg_code}
    EOH
  end

  let(:dsc_user_prefix) { "dsc" }
  let(:dsc_user_suffix) { "chefx" }
  let(:dsc_user) { "#{dsc_user_prefix}_usr_#{dsc_user_suffix}" }
  let(:dsc_user_prefix_env_var_name) { "dsc_user_env_prefix" }
  let(:dsc_user_suffix_env_var_name) { "dsc_user_env_suffix" }
  let(:dsc_user_prefix_env_code) { "$env:#{dsc_user_prefix_env_var_name}" }
  let(:dsc_user_suffix_env_code) { "$env:#{dsc_user_suffix_env_var_name}" }
  let(:dsc_user_prefix_param_name) { "dsc_user_prefix_param" }
  let(:dsc_user_suffix_param_name) { "dsc_user_suffix_param" }
  let(:dsc_user_prefix_param_code) { "$#{dsc_user_prefix_param_name}" }
  let(:dsc_user_suffix_param_code) { "$#{dsc_user_suffix_param_name}" }
  let(:dsc_user_env_code) { "\"$(#{dsc_user_prefix_env_code})_usr_$(#{dsc_user_suffix_env_code})\"" }
  let(:dsc_user_param_code) { "\"$(#{dsc_user_prefix_param_code})_usr_$(#{dsc_user_suffix_param_code})\"" }

  let(:config_flags) { nil }
  let(:config_params) do
    <<-EOH

    [CmdletBinding()]
    param
    (
    $#{dsc_user_prefix_param_name},
    $#{dsc_user_suffix_param_name}
    )
    EOH
  end

  let(:config_param_section) { "" }
  let(:dsc_user_code) { "'#{dsc_user}'" }
  let(:dsc_user_prefix_code) { dsc_user_prefix }
  let(:dsc_user_suffix_code) { dsc_user_suffix }
  let(:dsc_script_environment_attribute) { nil }
  let(:dsc_user_resources_code) do
    <<~EOH
        #{config_param_section}
      node localhost
      {
      $testuser = #{dsc_user_code}
      $testpassword = ConvertTo-SecureString -String "jf9a8m49jrajf4#" -AsPlainText -Force
      $testcred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $testuser, $testpassword

      User dsctestusercreate
      {
          UserName = $testuser
          Password = $testcred
          Description = "DSC test user"
          Ensure = "Present"
          Disabled = $false
          PasswordNeverExpires = $true
          PasswordChangeRequired = $false
      }
      }
    EOH
  end

  let(:dsc_user_config_data) do
    <<~EOH
      @{
          AllNodes = @(
              @{
                  NodeName = "localhost";
                  PSDscAllowPlainTextPassword = $true
              }
          )
      }

    EOH
  end

  let(:dsc_environment_env_var_name) { "dsc_test_cwd" }
  let(:dsc_environment_no_fail_not_etc_directory) { "#{ENV["systemroot"]}\\system32" }
  let(:dsc_environment_fail_etc_directory) { "#{ENV["systemroot"]}\\system32\\drivers\\etc" }
  let(:exception_message_signature) { "LL927-LL928" }
  let(:dsc_environment_config) do
    <<~EOH
      if (($pwd.path -eq '#{dsc_environment_fail_etc_directory}') -and (test-path('#{dsc_environment_fail_etc_directory}')))
      {
          throw 'Signature #{exception_message_signature}: Purposefully failing because cwd == #{dsc_environment_fail_etc_directory}'
      }
      environment "whatsmydir"
      {
          Name = '#{dsc_environment_env_var_name}'
          Value = $pwd.path
          Ensure = 'Present'
      }
    EOH
  end

  let(:dsc_config_name) do
    dsc_test_resource_base.name
  end
  let(:dsc_resource_from_code) do
    dsc_test_resource_base.code(dsc_code)
    dsc_test_resource_base
  end
  let(:config_name_value) { dsc_test_resource_base.name }

  let(:dsc_resource_from_path) do
    dsc_test_resource_base.command(create_config_script_from_code(dsc_code, config_name_value))
    dsc_test_resource_base
  end

  before(:each) do
    test_key_resource = Chef::Resource::RegistryKey.new(test_registry_key, dsc_test_run_context)
    test_key_resource.recursive(true)
    test_key_resource.run_action(:delete_key)
  end

  after(:each) do
    test_key_resource = Chef::Resource::RegistryKey.new(test_registry_key, dsc_test_run_context)
    test_key_resource.recursive(true)
    test_key_resource.run_action(:delete_key)
  end

  shared_examples_for "a dsc_script resource with specified PowerShell configuration code" do
    let(:test_registry_data) { test_registry_data1 }
    it "should create a registry key with a specific registry value and data" do
      expect(dsc_test_resource.registry_key_exists?(test_registry_key)).to eq(false)
      dsc_test_resource.run_action(:run)
      expect(dsc_test_resource.registry_key_exists?(test_registry_key)).to eq(true)
      expect(dsc_test_resource.registry_value_exists?(test_registry_key, { name: test_registry_value, type: :string, data: test_registry_data })).to eq(true)
    end

    it_should_behave_like "a dsc_script resource with configuration affected by cwd"
  end

  shared_examples_for "a dsc_script resource with configuration affected by cwd" do
    after(:each) do
      removal_resource = Chef::Resource::DscScript.new(dsc_test_resource_name, dsc_test_run_context)
      removal_resource.code <<~EOH
        environment 'removethis'
        {
           Name = '#{dsc_environment_env_var_name}'
           Ensure = 'Absent'
        }
      EOH
      removal_resource.run_action(:run)
    end

    describe "when the DSC configuration contains code that raises an exception if cwd has a specific value" do
      let(:dsc_code) { dsc_environment_config }
      it "should not raise an exception if the cwd is not etc" do
        dsc_test_resource.cwd(dsc_environment_no_fail_not_etc_directory)
        expect { dsc_test_resource.run_action(:run) }.not_to raise_error
      end

      it "should raise an exception if the cwd is etc" do
        dsc_test_resource.cwd(dsc_environment_fail_etc_directory)
        expect { dsc_test_resource.run_action(:run) }.to raise_error(Chef::Exceptions::PowershellCmdletException)
        begin
          dsc_test_resource.run_action(:run)
        rescue Chef::Exceptions::PowershellCmdletException => e
          expect(e.message).to match(exception_message_signature)
        end
      end
    end
  end

  shared_examples_for "a parameterized DSC configuration script" do
    let(:dsc_user_prefix_code) { dsc_user_prefix_env_code }
    let(:dsc_user_suffix_code) { dsc_user_suffix_env_code }
    it_behaves_like "a dsc_script with configuration that uses environment variables"
  end

  shared_examples_for "a dsc_script without configuration data that takes parameters" do
    context "when configuration data is not specified" do

      before(:each) do
        test_key_resource = Chef::Resource::RegistryKey.new(test_registry_key, dsc_test_run_context)
        test_key_resource.recursive(true)
        test_key_resource.run_action(:delete_key)
      end

      after(:each) do
        test_key_resource = Chef::Resource::RegistryKey.new(test_registry_key, dsc_test_run_context)
        test_key_resource.recursive(true)
        test_key_resource.run_action(:delete_key)
      end

      let(:test_registry_data) { test_registry_data1 }
      let(:dsc_parameterized_env_param_value) { "val" + Random.rand.to_s }

      it "should have a default value of nil for the configuration_data attribute" do
        expect(dsc_test_resource.configuration_data).to eql(nil)
      end

      it "should have a default value of nil for the configuration_data_path attribute" do
        expect(dsc_test_resource.configuration_data_script).to eql(nil)
      end

      let(:dsc_test_resource) { dsc_resource_from_path }
      let(:registry_embedded_parameters) { "" }
      let(:dsc_code) { dsc_reg_script }

      it "should set a registry key according to parameters passed to the configuration" do
        dsc_test_resource.configuration_name(config_name_value)
        dsc_test_resource.flags({ "#{reg_key_name_param_name}": test_registry_key, "#{reg_key_value_param_name}": test_registry_value })
        expect(dsc_test_resource.registry_key_exists?(test_registry_key)).to eq(false)
        dsc_test_resource.run_action(:run)
        expect(dsc_test_resource.registry_key_exists?(test_registry_key)).to eq(true)
        expect(dsc_test_resource.registry_value_exists?(test_registry_key, { name: test_registry_value, type: :string, data: test_registry_data })).to eq(true)
      end
    end
  end

  shared_examples_for "a dsc_script with configuration data" do
    let(:configuration_data_attribute) { "configuration_data" }
    it_behaves_like "a dsc_script with configuration data set via an attribute"

    let(:configuration_data_attribute) { "configuration_data_script" }
    it_behaves_like "a dsc_script with configuration data set via an attribute"
  end

  shared_examples_for "a dsc_script with configuration data set via an attribute" do
    it "should run a configuration script that creates a user" do
      config_data_value = dsc_user_config_data
      dsc_test_resource.configuration_name(config_name_value)
      if configuration_data_attribute == "configuration_data_script"
        config_data_value = create_config_script_from_code(dsc_user_config_data, "", true)
      end
      dsc_test_resource.environment({ dsc_user_prefix_env_var_name => dsc_user_prefix,
                                      dsc_user_suffix_env_var_name => dsc_user_suffix })
      dsc_test_resource.send(configuration_data_attribute, config_data_value)
      dsc_test_resource.flags(config_flags)
      expect(user_exists?(dsc_user)).to eq(false)
      expect { dsc_test_resource.run_action(:run) }.not_to raise_error
      expect(user_exists?(dsc_user)).to eq(true)
    end
  end

  shared_examples_for "a dsc_script with configuration data that takes parameters" do
    let(:dsc_user_code) { dsc_user_param_code }
    let(:config_param_section) { config_params }
    let(:config_flags) { { "#{dsc_user_prefix_param_name}": (dsc_user_prefix).to_s, "#{dsc_user_suffix_param_name}": (dsc_user_suffix).to_s } }
    it "does not directly contain the user name" do
      configuration_script_content = ::File.open(dsc_test_resource.command, &:read)
      expect(configuration_script_content.include?(dsc_user)).to be(false)
    end
    it_behaves_like "a dsc_script with configuration data"
  end

  shared_examples_for "a dsc_script with configuration data that uses environment variables" do
    let(:dsc_user_code) { dsc_user_env_code }

    it "does not directly contain the user name" do
      configuration_script_content = ::File.open(dsc_test_resource.command, &:read)
      expect(configuration_script_content.include?(dsc_user)).to be(false)
    end
    it_behaves_like "a dsc_script with configuration data"
  end

  context "when supplying configuration through the configuration attribute" do
    let(:dsc_test_resource) { dsc_resource_from_code }
    it_behaves_like "a dsc_script resource with specified PowerShell configuration code"
  end

  context "when supplying configuration using the path attribute" do
    let(:dsc_test_resource) { dsc_resource_from_path }
    it_behaves_like "a dsc_script resource with specified PowerShell configuration code"
  end

  context "when running a configuration that manages users" do
    before(:each) do
      delete_user(dsc_user)
    end

    let(:dsc_code) { dsc_user_resources_code }
    let(:config_name_value) { "DSCTestConfig" }
    let(:dsc_test_resource) { dsc_resource_from_path }

    it_behaves_like "a dsc_script with configuration data"
    it_behaves_like "a dsc_script with configuration data that uses environment variables"
    it_behaves_like "a dsc_script with configuration data that takes parameters"
    it_behaves_like "a dsc_script without configuration data that takes parameters"
  end

  context "when using ps_credential" do
    include IntegrationSupport

    before(:each) do
      delete_user(dsc_user)
      dsc_test_run_context.node.consume_external_attrs(OHAI_SYSTEM.data, {})
    end

    let(:configuration_data_path) { 'C:\\configurationdata.psd1' }

    let(:self_signed_cert_path) do
      File.join(CHEF_SPEC_DATA, "dsc_lcm.pfx")
    end

    let(:dsc_configuration_script) do
      <<~MYCODE
        cd c:\\
        configuration LCM
        {
          param ($thumbprint)
          localconfigurationmanager
          {
            RebootNodeIfNeeded = $false
            ConfigurationMode = 'ApplyOnly'
            CertificateID = $thumbprint
          }
        }
        $cert = ls Cert:\\LocalMachine\\My\\ |
          Where-Object {$_.Subject -match "ChefTest"} |
          Select -first 1

        if($cert -eq $null) {
          $pfxpath = '#{self_signed_cert_path}'
          $password = ''
          $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfxpath, $password, ([System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeyset))
          $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "My", ([System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
          $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
          $store.Add($cert)
          $store.Close()
        }

        lcm -thumbprint $cert.thumbprint
        set-dsclocalconfigurationmanager -path ./LCM
        $ConfigurationData = @"
        @{
        AllNodes = @(
          @{
          NodeName = "localhost";
          CertificateID = '$($cert.thumbprint)';
          };
        );
        }
        "@
        $ConfigurationData | out-file '#{configuration_data_path}' -force
      MYCODE
    end

    let(:powershell_script_resource) do
      Chef::Resource::PowershellScript.new("configure-lcm", dsc_test_run_context).tap do |r|
        r.code(dsc_configuration_script)
        r.architecture(:x86_64)
      end
    end

    let(:dsc_script_resource) do
      dsc_test_resource_base.tap do |r|
        r.code <<~EOF
          User dsctestusercreate
          {
              UserName = '#{dsc_user}'
              Password = #{r.ps_credential("jf9a8m49jrajf4#")}
              Ensure = "Present"
          }
        EOF
        r.configuration_data_script(configuration_data_path)
      end
    end

    it "allows the use of ps_credential" do
      skip("Skipped until we can adjust the test cert to meet the WMF 5 cert requirements.")
      expect(user_exists?(dsc_user)).to eq(false)
      powershell_script_resource.run_action(:run)
      expect(File).to exist(configuration_data_path)
      dsc_script_resource.run_action(:run)
      expect(user_exists?(dsc_user)).to eq(true)
    end
  end
end
