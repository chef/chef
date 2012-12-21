def ruby_19?
  !!(RUBY_VERSION =~ /^1.9/)
end

def ruby_18?
  !!(RUBY_VERSION =~ /^1.8/)
end

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

def windows_win2k3?
  return false unless windows?
  require 'ruby-wmi'

  host = WMI::Win32_OperatingSystem.find(:first)
  (host.version && host.version.start_with?("5.2"))
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

DEV_NULL = windows? ? 'NUL' : '/dev/null'
