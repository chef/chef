## Rubygems Customization ##
# Customize rubygems install behavior and locations to keep user gems isolated
# from the stuff we bundle with omnibus and any other ruby installations on the
# system.

# Always install and update new gems in "user install mode"
Gem::ConfigFile::OPERATING_SYSTEM_DEFAULTS["install"] = "--user"
Gem::ConfigFile::OPERATING_SYSTEM_DEFAULTS["update"] = "--user"

module Gem

  ##
  # Override user_dir to live inside of ~/.chefdk

  def self.user_dir
    parts = [Gem.user_home, '.chefdk', 'gem', ruby_engine]
    parts << RbConfig::CONFIG['ruby_version'] unless RbConfig::CONFIG['ruby_version'].empty?
    File.join parts
  end

end

