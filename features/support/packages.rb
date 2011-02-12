# Provides a method to quickly lookup whether we have
# a given packaging system installed.
def package_system_available?(name)
  case name
  when 'MacPorts'
    uname = `uname`
    (uname =~ /Darwin/ && File.exist?('/opt') && shell_out("which port").status.success?)
  else
    false
  end
end
