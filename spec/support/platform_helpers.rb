require "fcntl"
require "chef/mixin/shell_out"
require "ohai/mixin/http_helper"
require "ohai/mixin/gce_metadata"
require "spec/support/chef_helpers"

class ShellHelpers
  extend Chef::Mixin::ShellOut
end

# magic stolen from bundler/spec/support/less_than_proc.rb
class DependencyProc < Proc
  attr_accessor :present

  def self.with(present)
    provided = Gem::Version.new(present.dup)
    new do |required|
      !Gem::Requirement.new(required).satisfied_by?(provided)
    end.tap { |l| l.present = present }
  end

  def inspect
    "\"#{present}\""
  end
end

def ruby_64bit?
  RbConfig::CONFIG["host_cpu"].include?("x86_64")
end

def ruby_32bit?
  RbConfig::CONFIG["host_cpu"].include?("i686")
end

def windows?
  # NOTE this deliberately does not use ChefUtils.windows? because otherwise it would
  # pick up the node out of tests, while this tests the hosts running the specs.
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

def ohai
  # This is defined in spec_helper; it has the `platform` populated.
  OHAI_SYSTEM
end

require "wmi-lite/wmi" if windows?

def windows_domain_joined?
  return false unless windows?

  wmi = WmiLite::Wmi.new
  computer_system = wmi.first_of("Win32_ComputerSystem")
  computer_system["partofdomain"]
end

def windows_2012r2?
  return false unless windows?

  (win32_os_version && win32_os_version.start_with?("6.3"))
end

def windows_gte_10?
  return false unless windows?

  Gem::Requirement.new(">= 10").satisfied_by?(Gem::Version.new(win32_os_version))
end

def win32_os_version
  @win32_os_version ||= begin
    wmi = WmiLite::Wmi.new
    host = wmi.first_of("Win32_OperatingSystem")
    host["version"]
  end
end

def windows_powershell_dsc?
  return false unless windows?

  supports_dsc = false
  begin
    wmi = WmiLite::Wmi.new("root/microsoft/windows/desiredstateconfiguration")
    lcm = wmi.query("SELECT * FROM meta_class WHERE __this ISA 'MSFT_DSCLocalConfigurationManager'")
    supports_dsc = !! lcm
  rescue WmiLite::WmiException
  end
  supports_dsc
end

def windows_user_right?(right)
  return false unless windows?

  require "chef/win32/security"
  Chef::ReservedNames::Win32::Security.get_account_right(ENV["USERNAME"]).include?(right)
end

# detects if the hardware is 64-bit (evaluates to true in "WOW64" mode in a 32-bit app on a 64-bit system)
def windows64?
  windows? && ( ENV["PROCESSOR_ARCHITECTURE"] == "AMD64" || ENV["PROCESSOR_ARCHITEW6432"] == "AMD64" )
end

# detects if the hardware is 32-bit
def windows32?
  windows? && !windows64?
end

def unix?
  !windows?
end

def linux?
  RUBY_PLATFORM.include?("linux")
end

def macos?
  RUBY_PLATFORM.include?("darwin")
end

def macos_gte_11?
  macos? && !!(ohai[:platform_version].to_i >= 11)
end

def solaris?
  RUBY_PLATFORM.include?("solaris")
end

def freebsd?
  RUBY_PLATFORM.include?("freebsd")
end

def intel_64bit?
  !!(ohai[:kernel][:machine] == "x86_64")
end

def rhel?
  !!(ohai[:platform_family] == "rhel")
end

def rhel6?
  rhel? && !!(ohai[:platform_version].to_i == 6)
end

def opensuse?
  suse? && !!(ohai[:platform_version].to_i >= 15)
end

def rhel7?
  rhel? && !!(ohai[:platform_version].to_i == 7)
end

def rhel8?
  rhel? && !!(ohai[:platform_version].to_i == 8)
end

def rhel_gte_8?
  rhel? && !!(ohai[:platform_version].to_i >= 8)
end

def debian_family?
  !!(ohai[:platform_family] == "debian")
end

def aix?
  RUBY_PLATFORM.include?("aix")
end

def wpar?
  !((ohai[:virtualization] || {})[:wpar_no].nil?)
end

def supports_cloexec?
  Fcntl.const_defined?("F_SETFD") && Fcntl.const_defined?("FD_CLOEXEC")
end

def selinux_enabled?
  # This code is currently copied from lib/chef/util/selinux to make
  # specs independent of product.
  selinuxenabled_path = which("selinuxenabled")
  if selinuxenabled_path
    cmd = Mixlib::ShellOut.new(selinuxenabled_path, returns: [0, 1])
    cmd_result = cmd.run_command
    case cmd_result.exitstatus
    when 1
      false
    when 0
      true
    else
      raise "Unknown exit code from command #{selinuxenabled_path}: #{cmd.exitstatus}"
    end
  else
    # We assume selinux is not enabled if selinux utils are not
    # installed.
    false
  end
end

def suse?
  !!(ohai[:platform_family] == "suse")
end

def root?
  return false if windows?

  Process.euid == 0
end

def openssl_gte_101?
  OpenSSL::OPENSSL_VERSION_NUMBER >= 10001000
end

def openssl_lt_101?
  !openssl_gte_101?
end

def aes_256_gcm?
  OpenSSL::Cipher.ciphers.include?("aes-256-gcm")
end

def fips?
  ENV["CHEF_FIPS"] == "1"
end

class HttpHelper
  extend Ohai::Mixin::HttpHelper
  def self.logger
    Chef::Log
  end
end

def gce?
  HttpHelper.can_socket_connect?(Ohai::Mixin::GCEMetadata::GCE_METADATA_ADDR, 80)
rescue SocketError
  false
end

def ifconfig?
  which("ifconfig")
end

def choco_installed?
  result = ShellHelpers.shell_out("choco --version")
  result.stderr.empty?
rescue
  false
end

def pwsh_installed?
  result = ShellHelpers.shell_out("pwsh.exe --version")
  result.stderr.empty?
rescue
  false
end
