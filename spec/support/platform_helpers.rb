
def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

# def jruby?

def unix?
  !windows?
end

if windows?
  LINE_ENDING = "\r\n"
  ECHO_LC_ALL = "echo %LC_ALL%"
else
  LINE_ENDING = "\n"
  ECHO_LC_ALL = "echo $LC_ALL"
end
