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

  next if gem_name.match?(/ruby.shadow/) && RUBY_PLATFORM.include?("aix")

  puts "re-installing #{gem_name}..."

  Dir.chdir(gempath) do
    system("gem build #{gem_name}.gemspec") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end
end

def patch_ssl_env_hack(ssl_env_hack)
  # the constant SSL_ENV_CACERT_PATCH is a proxy for whether the SSL_CERT_FILE environment variable
  # will be set by the ssl_env_hack.rb file.  This is used to ensure that the CA bundle
  # is set correctly in omnibus installations of Chef Infra Client if the user is using certs/cacert.pem
  # instead of cert.pem. Because we're reinstalling openssl gem for 3.x versions, we need to ensure that
  # openssl.rb requires ssl_env_hack.rb, which will set the SSL_CERT_FILE environment variable
  ssl_env_hack_patch = <<-PATCH
  SSL_ENV_CACERT_PATCH=true unless defined?(SSL_ENV_CACERT_PATCH)
  PATCH

  File.open(ssl_env_hack, "r+") do |f|
    unpatched_ssl_env_hack_rb = f.read
    if unpatched_ssl_env_hack_rb =~ /SSL_ENV_CACERT_PATCH/
      puts "skipping #{ssl_env_hack} as it already has SSL_ENV_CACERT_PATCH"
      next
    end

    f.rewind
    f.write(ssl_env_hack_patch)
    f.write(unpatched_ssl_env_hack_rb)
  end
  puts "patched #{ssl_env_hack} to include SSL_ENV_CACERT_PATCH"
end

def patch_openssl(openssl)
  puts openssl
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
  puts "patched #{openssl} to include ssl_env_hack"
end

if RUBY_PLATFORM =~ /mswin|mingw|windows/
  puts "Patching ssl_env_hack.rb to include SSL_ENV_CACERT_PATCH"

  # ssl_env_hack.rb in chef is superseded by foundation copy in omnibus,
  # but patch it if it doesn't have SSL_ENV_CACERT_PATCH defined.
  $:.each do |lib|
    puts "checking for ssl_env_hack in #{lib}"
    Dir["#{lib}/**/ssl_env_hack.rb"].each do |ssl_env_hack|
      puts "found #{ssl_env_hack}"
      patch_ssl_env_hack(ssl_env_hack)
      File.readlines(ssl_env_hack).each do |line|
        puts line
      end
    end
  end

  puts "Found openssl.rb files in the following gem paths:"
  Dir["#{gem_home}/**/openssl-*/lib/openssl.rb"].each do |openssl|
    patch_openssl(openssl)
  end

  puts "Patch openssl.rb in the load path as well"
  $:.each do |lib|
    openssl_rb = File.join(lib, "openssl.rb")
    patch_openssl(openssl_rb) if File.exist?(openssl_rb)
  end

  puts "Including openssl"
  require "openssl"
  puts "::SSL_ENV_CACERT_PATCH is #{defined?(::SSL_ENV_CACERT_PATCH) ? "defined" : "not defined"}"
end
