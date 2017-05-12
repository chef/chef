require "fcntl"
require "chef/mixin/shell_out"
require "ohai/mixin/http_helper"
require "ohai/mixin/gce_metadata"
require "chef/mixin/powershell_out"

class ShellHelpers
  extend Chef::Mixin::ShellOut
  extend Chef::Mixin::PowershellOut
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
  !!(RbConfig::CONFIG["host_cpu"] =~ /x86_64/)
end

def ruby_32bit?
  !!(RbConfig::CONFIG["host_cpu"] =~ /i686/)
end

def windows?
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

def windows_win2k3?
  return false unless windows?
  (host_version && host_version.start_with?("5.2"))
end

def windows_2008r2_or_later?
  return false unless windows?
  return false unless host_version
  components = host_version.split(".").map do |component|
    component.to_i
  end
  components.length >= 2 && components[0] >= 6 && components[1] >= 1
end

def windows_2012r2?
  return false unless windows?
  (host_version && host_version.start_with?("6.3"))
end

def host_version
  @host_version ||= begin
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

def windows_nano_server?
  require "chef/platform/query_helpers"
  Chef::Platform.windows_nano_server?
end

def windows_user_right?(right)
  return false unless windows?
  require "chef/win32/security"
  Chef::ReservedNames::Win32::Security.get_account_right(ENV["USERNAME"]).include?(right)
end

def mac_osx_106?
  if File.exists? "/usr/bin/sw_vers"
    result = ShellHelpers.shell_out("/usr/bin/sw_vers")
    result.stdout.each_line do |line|
      if line =~ /^ProductVersion:\s10.6.*$/
        return true
      end
    end
  end

  false
end

def mac_osx?
  if File.exists? "/usr/bin/sw_vers"
    result = ShellHelpers.shell_out("/usr/bin/sw_vers")
    result.stdout.each_line do |line|
      if line =~ /^ProductName:\sMac OS X.*$/
        return true
      end
    end
  end

  false
end

# detects if the hardware is 64-bit (evaluates to true in "WOW64" mode in a 32-bit app on a 64-bit system)
def windows64?
  windows? && ( ENV["PROCESSOR_ARCHITECTURE"] == "AMD64" || ENV["PROCESSOR_ARCHITEW6432"] == "AMD64" )
end

# detects if the hardware is 32-bit
def windows32?
  windows? && !windows64?
end

# def jruby?

def unix?
  !windows?
end

def linux?
  !!(RUBY_PLATFORM =~ /linux/)
end

def os_x?
  !!(RUBY_PLATFORM =~ /darwin/)
end

def solaris?
  !!(RUBY_PLATFORM =~ /solaris/)
end

def freebsd?
  !!(RUBY_PLATFORM =~ /freebsd/)
end

def debian_family?
  !!(ohai[:platform_family] == "debian")
end

def aix?
  !!(RUBY_PLATFORM =~ /aix/)
end

def wpar?
  !((ohai[:virtualization] || {})[:wpar_no].nil?)
end

def supports_cloexec?
  Fcntl.const_defined?("F_SETFD") && Fcntl.const_defined?("FD_CLOEXEC")
end

DEV_NULL = windows? ? "NUL" : "/dev/null"

def selinux_enabled?
  # This code is currently copied from lib/chef/util/selinux to make
  # specs independent of product.
  selinuxenabled_path = which("selinuxenabled")
  if selinuxenabled_path
    cmd = Mixlib::ShellOut.new(selinuxenabled_path, :returns => [0, 1])
    cmd_result = cmd.run_command
    case cmd_result.exitstatus
    when 1
      return false
    when 0
      return true
    else
      raise "Unknown exit code from command #{selinuxenabled_path}: #{cmd.exitstatus}"
    end
  else
    # We assume selinux is not enabled if selinux utils are not
    # installed.
    return false
  end
end

def suse?
  File.exists?("/etc/SuSE-release")
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
end

def gce?
  HttpHelper.can_socket_connect?(Ohai::Mixin::GCEMetadata::GCE_METADATA_ADDR, 80)
rescue SocketError
  false
end

def choco_installed?
  result = ShellHelpers.powershell_out("choco --version")
  result.stderr.empty? ? true : false
end
