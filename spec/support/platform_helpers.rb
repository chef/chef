def ruby_19?
  !!(RUBY_VERSION =~ /^1.9/)
end

def ruby_18?
  !!(RUBY_VERSION =~ /^1.8/)
end

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
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
