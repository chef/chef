# Provides a method to quickly lookup whether we have
# a given packaging system installed.
def package_system_available?(name)
  case name
  when 'MacPorts'
    uname = `uname`
    port = `which port`
    (uname =~ /Darwin/ and !port.match(/not found/))
  else
    false
  end
end
