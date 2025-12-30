# on Windows, the directory location starts with "(eval at " because it's
# being evaled in
file_directory = File.dirname(__FILE__).gsub("(eval at ", "")
$:.unshift(File.join(file_directory, "lib"))
vs_path = File.expand_path("chef-utils/lib/chef-utils/version_string.rb", __dir__)

if File.exist?(vs_path)
  # include chef-utils/lib in the path if we're inside of chef vs. chef-utils gem
  # but add it to the end of the search path
  $: << File.join(file_directory, "chef-utils", "lib")
end
# if the path doesn't exist then we're just in the wild gem and not in the git repo
require "chef-utils/version_string"
require "chef/version"

Gem::Specification.new do |s|
  s.name = "chef"
  s.version = Chef::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.md", "LICENSE"]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Adam Jacob"
  s.email = "adam@chef.io"
  s.homepage = "https://www.chef.io"

  if RUBY_PLATFORM =~ /aix/
    s.required_ruby_version = ">= 3.0.3"
  else
    s.required_ruby_version = ">= 3.1.0"
  end

  s.add_dependency "chef-config", "= #{Chef::VERSION}"
  s.add_dependency "chef-utils", "= #{Chef::VERSION}"
  s.add_dependency "train-core", "~> 3.13", ">= 3.13.4" # Updated to be compatible with InSpec 7
  s.add_dependency "train-winrm", ">= 0.2.17"
  s.add_dependency "train-rest", ">= 0.4.1" # target mode with rest APIs

  s.add_dependency "license-acceptance", ">= 1.0.5", "< 3"
  s.add_dependency "mixlib-cli", ">= 2.1.1", "< 3.0"
  s.add_dependency "mixlib-log", ">= 2.0.3", "< 4.0"
  s.add_dependency "mixlib-authentication", ">= 2.1", "< 4"
  s.add_dependency "mixlib-shellout", "~> 3.3.8"
  s.add_dependency "mixlib-archive", ">= 0.4", "< 2.0"
  s.add_dependency "ohai", "~> 19.0"
  s.add_dependency "inspec-core", "~> 7.0.95"

  s.add_dependency "ffi", ">= 1.15.5", "< 1.18.0"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "net-sftp", ">= 2.1.2", "< 5.0" # remote_file resource
  s.add_dependency "net-ftp" # remote_file resource
  s.add_dependency "ed25519", "~> 1.2" # ssh-ed25519 support for target mode
  s.add_dependency "bcrypt_pbkdf", "~> 1.0" # ssh-ed25519 support for target mode
  s.add_dependency "erubis", "~> 2.7" # template resource / cookbook syntax check
  s.add_dependency "diff-lcs", "~> 1.6.0" # Used in lib/chef/util/diff
  s.add_dependency "ffi-libarchive", "~> 1.0", ">= 1.0.3" # archive_file resource
  s.add_dependency "chef-zero", "~> 15.1.0"
  s.add_dependency "chef-vault" # chef-vault resources and helpers

  s.add_dependency "plist", "~> 3.2" # launchd, dscl/mac user, macos_userdefaults, and plist resources
  s.add_dependency "iniparse", "~> 1.4" # systemd_unit resource
  s.add_dependency "addressable"
  s.add_dependency "syslog"
  s.add_dependency "csv", "~> 3.3.5" # really needs to come from inspec?
  s.add_dependency "syslog-logger", "~> 1.6"
  s.add_dependency "unf_ext", "~> 0.0.9.1" # older platforms
  s.add_dependency "uri", "~> 1.0.4" # CVE-2025-61594 fixed in >= 1.0.4
  s.add_dependency "corefoundation", "~> 0.3.4" # macos_userdefaults resource

  s.add_dependency "proxifier2", "~> 1.1"

  s.add_dependency "aws-sdk-s3", "~> 1.91" # s3 recipe-url support
  s.add_dependency "aws-sdk-secretsmanager", "~> 1.46"
  s.add_dependency "vault", "~> 0.18.2" # hashi vault official client gem
  s.add_dependency "chef-licensing", "~> 1.3"

  s.bindir = "bin"
  s.executables = %w{ }

  s.require_paths = %w{ lib }
  s.files = %w{Gemfile Rakefile LICENSE README.md} +
    Dir.glob("{lib}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) } +
    Dir.glob("*.gemspec")

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/chef/chef/issues",
    "changelog_uri" => "https://github.com/chef/chef/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://docs.chef.io/",
    "homepage_uri" => "https://www.chef.io",
    "mailing_list_uri" => "https://discourse.chef.io/",
    "source_code_uri" => "https://github.com/chef/chef/",
  }
end
