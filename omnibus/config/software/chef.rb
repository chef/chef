name "chef"
default_version "local_source"

license :project_license

# For the specific super-special version "local_source", build the source from
# the local git checkout. This is what you'd want to occur by default if you
# just ran omnibus build locally.
version("local_source") do
  source path: File.expand_path("../..", project.files_path),
         # Since we are using the local repo, we try to not copy any files
         # that are generated in the process of bundle installing omnibus.
         # If the install steps are well-behaved, this should not matter
         # since we only perform bundle and gem installs from the
         # omnibus cache source directory, but we do this regardless
         # to maintain consistency between what a local build sees and
         # what a github based build will see.
         options: { exclude: [ "omnibus/vendor" ] }
end

# For any version other than "local_source", fetch from github.
if version != "local_source"
  source git: "git://github.com/chef/chef.git"
end

# For nokogiri
dependency "libxml2"
dependency "libxslt"
dependency "libiconv"
dependency "liblzma"
dependency "zlib"

# ruby and bundler and friends
dependency "ruby"
dependency "rubygems"
dependency "bundler"

# Install all the native gems separately
# Worst offenders first to take best advantage of cache:
dependency "chef-gem-ffi-yajl"
dependency "chef-gem-ohai"
dependency "chef-gem-nokogiri"
dependency "chef-gem-libyajl2"
dependency "chef-gem-ruby-prof"
dependency "chef-gem-byebug"
dependency "chef-gem-debug_inspector"
dependency "chef-gem-binding_of_caller"
unless ios_xr? || solaris?
  dependency "chef-gem-rbnacl-libsodium"
  dependency "chef-gem-bcrypt_pbkdf-ruby"
end

# Now everyone else, in alphabetical order because we don't care THAT much
Dir.entries(File.dirname(__FILE__)).sort.each do |gem_software|
  if gem_software =~ /^(chef-gem-.+)\.rb$/
    dependency $1
  end
end

build do
  # This is where we get the definitions below
  require_relative "../../files/chef/build-chef"
  extend BuildChef

  project_env = env.dup
  project_env["BUNDLE_GEMFILE"] = project_gemfile

  # Prepare to install: build config, retries, job, frozen=true
  # TODO Windows install seems to sometimes install already-installed gems such
  # as gherkin (and fail as a result) if you use jobs > 1.
  create_bundle_config(project_gemfile, retries: 4, jobs: windows? ? 1 : 7, frozen: true)

  # Install all the things. Arguments are specified in .bundle/config (see create_bundle_config)
  block { log.info(log_key) { "" } }
  bundle "install --verbose", env: project_env

  # Check that it worked
  block { log.info(log_key) { "" } }
  bundle "check", env: project_env

  # fix up git-sourced gems
  properly_reinstall_git_and_path_sourced_gems
  install_shared_gemfile

  # Check that the final gemfile worked
  block { log.info(log_key) { "" } }
  bundle "check", env: env, cwd: File.dirname(shared_gemfile)
end
