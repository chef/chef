require 'fcntl'
require 'chef/mixin/shell_out'


class ShellHelpers
  extend Chef::Mixin::ShellOut
end

def ruby_lt_20?
  !ruby_gte_20?
end

def chef_gte_13?
  Chef::VERSION.split('.').first.to_i >= 13
end

def chef_lt_13?
  Chef::VERSION.split('.').first.to_i < 13
end

def ruby_gte_19?
  RUBY_VERSION.to_f >= 1.9
end

def ruby_20?
  !!(RUBY_VERSION =~ /^2.0/)
end

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

def ohai
  # This is defined in spec_helper; it has the `platform` populated.
  OHAI_SYSTEM
end

require 'wmi-lite/wmi' if windows?

def windows_domain_joined?
  return false unless windows?
  wmi = WmiLite::Wmi.new
  computer_system = wmi.first_of('Win32_ComputerSystem')
  computer_system['partofdomain']
end

def windows_win2k3?
  return false unless windows?
  wmi = WmiLite::Wmi.new
  host = wmi.first_of('Win32_OperatingSystem')
  (host['version'] && host['version'].start_with?("5.2"))
end

def windows_2008r2_or_later?
  return false unless windows?
  wmi = WmiLite::Wmi.new
  host = wmi.first_of('Win32_OperatingSystem')
  version = host['version']
  return false unless version
  components = version.split('.').map do | component |
    component.to_i
  end
  components.length >=2 && components[0] >= 6 && components[1] >= 1
end

def windows_powershell_dsc?
  return false unless windows?
  supports_dsc = false
  begin
    wmi = WmiLite::Wmi.new('root/microsoft/windows/desiredstateconfiguration')
    lcm = wmi.query("SELECT * FROM meta_class WHERE __this ISA 'MSFT_DSCLocalConfigurationManager'")
    supports_dsc = !! lcm
  rescue WmiLite::WmiException
  end
  supports_dsc
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
  windows? && ( ENV['PROCESSOR_ARCHITECTURE'] == 'AMD64' || ENV['PROCESSOR_ARCHITEW6432'] == 'AMD64' )
end

# detects if the hardware is 32-bit
def windows32?
  windows? && !windows64?
end

# def jruby?

def unix?
  !windows?
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

def aix?
  !!(RUBY_PLATFORM =~ /aix/)
end

def supports_cloexec?
  Fcntl.const_defined?('F_SETFD') && Fcntl.const_defined?('FD_CLOEXEC')
end

DEV_NULL = windows? ? 'NUL' : '/dev/null'

def selinux_enabled?
  # This code is currently copied from lib/chef/util/selinux to make
  # specs independent of product.
  selinuxenabled_path = which("selinuxenabled")
  if selinuxenabled_path
    cmd = Mixlib::ShellOut.new(selinuxenabled_path, :returns => [0,1])
    cmd_result = cmd.run_command
    case cmd_result.exitstatus
    when 1
      return false
    when 0
      return true
    else
      raise RuntimeError, "Unknown exit code from command #{selinuxenabled_path}: #{cmd.exitstatus}"
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
