#!/usr/bin/env ruby

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  matches = File.basename(gempath).match(/.*-[A-Fa-f0-9]{12}/)
  next unless matches

  gem_name = File.basename(Dir["#{gempath}/*.gemspec"].first, ".gemspec")
  # FIXME: should strip any valid ruby platform off of the gem_name if it matches

  next unless gem_name

  # FIXME: should omit the gem which is in the current directory and not hard code chef
  next if %w{chef chef-universal-mingw-ucrt proxifier}.include?(gem_name)

  puts "re-installing #{gem_name}..."

  Dir.chdir(gempath) do
    system("gem build #{gem_name}.gemspec") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end
end

if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  puts "Found openssl.rb files in the following gem paths:"
  Dir["#{gem_home}/**/openssl.rb"].each do |gempath|
    puts gempath
  end
  Dir["#{gem_home}/**/openssl-*/lib/openssl.rb"].each do |openssl|
    File.open(openssl, "r+") do |f|
      unpatched_openssl_rb = f.read
      if unpatched_openssl_rb =~ /require\s+['"]ssl_env_hack['"]/
        puts "skipping #{openssl} as it already has ssl_env_hack"
        next
      end

      f.rewind
      # This is a workaround for the openssl gem not being able to find the CA bundle in omnibus installations
      # and not setting SSL_CERT_FILE if it's not already set.
      f.write("\nrequire 'ssl_env_hack'\n")
      f.write(unpatched_openssl_rb)
    end
  end
end