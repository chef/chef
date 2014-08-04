require 'fcntl'
require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

def ruby_gte_20?
  RUBY_VERSION.to_f >= 2.0
end

def ruby_gte_19?
  RUBY_VERSION.to_f >= 1.9
end

def ruby_20?
  !!(RUBY_VERSION =~ /^2.0/)
end

def ruby_19?
  !!(RUBY_VERSION =~ /^1.9/)
end

def ruby_18?
  !!(RUBY_VERSION =~ /^1.8/)
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

def mac_osx_106?
  if File.exists? "/usr/bin/sw_vers"
    result = shell_out("/usr/bin/sw_vers")
    result.stdout.each_line do |line|
      if line =~ /^ProductVersion:\s10.6.*$/
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
