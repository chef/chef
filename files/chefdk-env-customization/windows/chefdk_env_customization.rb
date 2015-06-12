## Environment hacks for running Ruby with ChefDK ##
# ENV['HOME'] is not set by default on Windows. We need to set this to
# something sensible since a lot of Ruby code depends on it. It is important 
# for this directory to exist and be available, so we are introducing logic
# here to pick a working HOME
#
# You can find this file in the repo at https://github.com/chef/omnibus-chef

if !ENV['HOME'] || !File.exists?(ENV['HOME'])
  old_home = ENV['HOME']
  found = false
  alternate_homes = []
  alternate_homes << "#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}" if ENV['HOMEDRIVE']
  alternate_homes << "#{ENV['USERPROFILE']}" if ENV['USERPROFILE']

  alternate_homes.each do |path|
    if File.exists?(path)
      ENV['HOME'] = path
      found = true
      break
    end
  end

  STDERR.puts <<-EOF
The HOME (#{old_home}) environment variable was not set, or was set to
an inaccessible location. Because this can prevent you from running many
of the programs included with ChefDK, we will attempt to find another
suitable location.

  EOF

  if found
    STDERR.puts <<-EOF
Falling back to using #{ENV['HOME']} as the home directory. If you would like
to use another directory as HOME, please set the HOME environment variable.
    EOF
  else
    STDERR.puts <<-EOF
Could not find a suitable HOME directory. Tried:
#{alternate_homes.join("\n")}

Some Ruby binaries may not function correctly. You can set the HOME 
environment variable to a directory that exists to try to solve this.
    EOF
  end

  STDERR.puts <<-EOF

If you would not like ChefDK to try to fix the HOME environment variable,
check the CHEFDK_ENV_FIX environment variable. Setting this value to 0
prevent this modification to your HOME environment variable.

  EOF
end
