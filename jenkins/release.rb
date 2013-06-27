#!/usr/bin/env ruby

## release.rb #################################################################
#------------------------------------------------------------------------------
# This script runs from the root of a jenkins workspace where artifacts from
# the omnibus build matrix are collected.
#
# # Primary command line options:
# * `--project PROJECT`: Project to be released. This also controls where the
#   script looks for config JSON.
# * `--bucket S3_BUCKET`: Name of the S3 bucket where artifacts are released
#   to.
#
# Other options are available, run `release.rb --help`.
#
# # Config
# release.rb looks in the same directory where it's located for files named
# "$project.json" and "$project-platform-names.json".
#
# ## $project.json
# The project.json file controls the mapping of build platforms to release
# platforms so that a single build artifact can be reused on compatible
# platforms. See chef.json for an example.
#
# ## $project-platform-names.json
# The project-platform-names.json file maps short platform names to long ones.
# see chef-platform-names.json for an example.
#
# # Tests
# This file contains the script's tests. Tests are written in rspec. To run the
# tests, run rspec with this file as the argument, e.g.,
# `rspec -cfs release.rb`.

require 'optparse'
require 'digest'
require 'rubygems'
require 'json'
require 'mixlib/shellout'

# Represnts the collection of artifacts on disk that we plan to upload. Handles
# finding the artifacts and dealing with the mapping between build platform and
# install platforms.
class ArtifactCollection

  class MissingArtifact < RuntimeError
  end

  attr_reader :project
  attr_reader :config

  def initialize(project, config)
    @project = project
    @config = config
  end

  def platform_map_json
    IO.read(File.expand_path("../#{project}.json", __FILE__))
  end

  def platform_map
    JSON.parse(platform_map_json)
  end

  def platform_name_map_path
    File.expand_path("../#{project}-platform-names.json", __FILE__)
  end

  def platform_name_map_json
    IO.read(platform_name_map_path)
  end

  def platform_name_map
    JSON.parse(platform_name_map_json)
  end

  def package_paths
    @package_paths ||= Dir['**/pkg/*'].
      reject {|path| path.include?("BUILD_VERSION") }.
      reject {|path| path.include?("metadata.json") }
  end

  def artifacts
    artifacts = []
    missing_packages = []
    platform_map.each do |build_platform_spec, supported_platforms|
      if path = package_paths.find { |p| p.include?(build_platform_spec) }
        artifacts << Artifact.new(path, supported_platforms, config)
      else
        missing_packages << build_platform_spec
      end
    end
    error_on_missing_pkgs!(missing_packages)
    artifacts
  end

  def error_on_missing_pkgs!(missing_packages)
    unless missing_packages.empty?
      if config[:ignore_missing_packages]
        missing_packages.each do |pkg_config|
          # TODO: this should go to $stderr
          puts "WARN: Missing package for config: #{pkg_config}"
        end
      else
        raise MissingArtifact, "Missing packages for config(s): '#{missing_packages.join("' '")}'"
      end
    end
  end
end

# Represents an individual package which has one or more supported platforms.
class Artifact

  attr_reader :path
  attr_reader :platforms
  attr_reader :config

  def initialize(path, platforms, config)
    @path = path
    @platforms = platforms
    @config = config
  end

  # Adds the package to +release_manifest+, which is a Hash. The result is in this form:
  #   "el" => {
  #     "5" => { "x86_64" => { "11.4.0-1" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm" } }
  #   }
  # This method mutates the argument (hence the `!` at the end). The updated
  # release manifest is returned.
  def add_to_release_manifest!(release_manifest)
    platforms.each do |distro, version, arch|
      release_manifest[distro] ||= {}
      release_manifest[distro][version] ||= {}
      release_manifest[distro][version][arch] = { build_version => relpath }
      # TODO: when adding checksums, the desired format is like this:
      # build_support_json[platform][platform_version][machine_architecture][options[:version]]["relpath"] = build_location
    end
    release_manifest
  end

  # Adds the package to +release_manifest+, which is a Hash. The result is in this form:
  #   "el" => {
  #     "5" => {
  #       "x86_64" => {
  #         "11.4.0-1" => {
  #           "relpath" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm",
  #           "md5" => "123f00d...",
  #           "sha256" => 456beef..."
  #         }
  #       }
  #     }
  #   }
  # This method mutates the argument (hence the `!` at the end). The updated
  # release manifest is returned.
  def add_to_v2_release_manifest!(release_manifest)
    platforms.each do |distro, version, arch|
      pkg_info = {
        "relpath" => relpath,
        "md5" => md5,
        "sha256" => sha256
      }

      release_manifest[distro] ||= {}
      release_manifest[distro][version] ||= {}
      release_manifest[distro][version][arch] = { build_version => pkg_info  }
    end
    release_manifest
  end

  def build_platform
    platforms.first
  end

  def build_version
    config[:version]
  end

  def relpath
    # upload build to build platform directory
    "/#{build_platform.join('/')}/#{path.split('/').last}"
  end

  def md5
    @md5 ||= digest(Digest::MD5)
  end

  def sha256
    @sha256 ||= digest(Digest::SHA256)
  end

  private

  def digest(digest_class)
    digest = digest_class.new
    File.open(path) do |io|
      while chunk = io.read(1024 * 8)
        digest.update(chunk)
      end
    end
    digest.hexdigest
  end
end

class ShipIt
  attr_reader :argv
  attr_reader :options

  def initialize(argv=[])
    @argv = argv
    @options = {:package_s3_config_file => "~/.s3cfg"}
  end

  def release_it
    $stdout.sync = true
    parse_options
    artifact_collection = ArtifactCollection.new(options[:project], options)
    artifacts = artifact_collection.artifacts

    v2_metadata = {}

    artifacts.each do |artifact|
      artifact.add_to_v2_release_manifest!(v2_metadata)
      upload_package(artifact.path, artifact.relpath)
    end
    upload_v2_platform_name_map(artifact_collection.platform_name_map_path)
    upload_v2_manifest(v2_metadata)
  end

  def option_parser
    @option_parser ||= OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-p", "--project PROJECT", "the project to release") do |project|
        options[:project] = project
      end

      opts.on("-v", "--version VERSION", "the version of the installer to release") do |version|
        options[:version] = version
      end

      opts.on("-b", "--bucket S3_BUCKET_NAME", "the name of the s3 bucket to release to") do |bucket|
        options[:bucket] = bucket
      end

      opts.on("-c", "--package-s3-config S3_CMD_CONFIG_FILE", "path to the s3cmd config file for packages bucket") do |config|
        options[:package_s3_config_file] = config
      end

      opts.on("-M", "--metadata-bucket S3_BUCKET_NAME", "the name of the S3 bucket for v2 metadata") do |bucket|
        options[:metadata_bucket] = bucket
      end

      opts.on("-m", "--metadata-s3-config S3_CMD_CONFIG_FILE", "path to the s3cmd config file for the v2 metadata AWS account") do |config_path|
        options[:metadata_s3_config_file] = config_path
      end

      opts.on("--ignore-missing-packages",
              "indicates the release should continue if any build packages are missing") do |missing|
        options[:ignore_missing_packages] = missing
      end
    end
  end

  def parse_options
    option_parser.parse(argv)

    # check for an optional BUILD_VERSION file which is generated by the build script
    if options[:version].nil?
      # this file should be the same across all platforms so grab the first one
      build_version_file = Dir['**/pkg/BUILD_VERSION'].first
      options[:version] = IO.read(build_version_file).chomp if build_version_file
    end

    required = [:project, :version, :bucket, :metadata_bucket, :metadata_s3_config_file]
    missing = required.select {|param| options[param].nil?}
    if !missing.empty?
      puts "Missing required options: #{missing.join(', ')}"
      puts option_parser
      exit 1
    end
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument
    puts $!.to_s
    puts option_parser
    exit 1
  end

  def shellout_opts
    {:timeout => 1200, :live_stream => STDOUT}
  end

  def progress
    if STDOUT.tty?
      "--progress"
    else
      "--no-progress"
    end
  end

  def upload_package(local_path, s3_path)
    s3_cmd = ["s3cmd",
              "-c #{options[:package_s3_config_file]}",
              "put",
              progress,
              "--acl-public",
              local_path,
              "s3://#{options[:bucket]}#{s3_path}"].join(" ")
    shell = Mixlib::ShellOut.new(s3_cmd, shellout_opts)
    shell.run_command
    shell.error!
  end

  def upload_v2_manifest(manifest)
    File.open("v2-release-manifest.json", "w") {|f| f.puts JSON.pretty_generate(manifest)}

    s3_location = "s3://#{options[:metadata_bucket]}/#{options[:project]}-release-manifest/#{options[:version]}.json"
    puts "UPLOAD: v2-release-manifest.json -> #{s3_location}"
    s3_cmd = ["s3cmd",
              "-c #{options[:metadata_s3_config_file]}",
              "put",
              "--acl-public",
              "v2-release-manifest.json",
              s3_location].join(" ")
    shell = Mixlib::ShellOut.new(s3_cmd, shellout_opts)
    shell.run_command
    shell.error!
  end

  def upload_v2_platform_name_map(platform_names_file)
    s3_location = "s3://#{options[:metadata_bucket]}/#{options[:project]}-release-manifest/#{options[:project]}-platform-names.json"
    puts "UPLOAD: #{options[:project]}-platform-names.json -> #{s3_location}"
    s3_cmd = ["s3cmd",
              "-c #{options[:metadata_s3_config_file]}",
              "put",
              "--acl-public",
              platform_names_file,
              s3_location].join(" ")
    shell = Mixlib::ShellOut.new(s3_cmd, shellout_opts)
    shell.run_command
    shell.error!
  end

  def upload_v2_manifest?
    !options[:metadata_bucket].nil?
  end
end


if !$0.include?("rspec")
  ShipIt.new(ARGV).release_it
else
  describe ArtifactCollection do

    # project_json is the thing that maps a build to. It is stored in the same
    # directory with basename determined by project, e.g., "chef.json" for
    # chef-client, "chef-server.json" for chef-server. By convention, the first
    # entry is the platform that we actually do the build on.
    let(:platform_map_json) do
      <<-E
{
    "build_os=centos-5,machine_architecture=x64,role=oss-builder": [
        [
            "el",
            "5",
            "x86_64"
        ],
        [
            "sles",
            "11.2",
            "x86_64"
        ]
    ],
    "build_os=centos-5,machine_architecture=x86,role=oss-builder": [
        [
            "el",
            "5",
            "i686"
        ],
        [
            "sles",
            "11.2",
            "i686"
        ]
    ]
}
E
    end

    let(:platform_map) do
      JSON.parse(platform_map_json)
    end

    # mapping of short platform names to longer ones.
    # This file lives in this script's directory under $project-platform-names.json
    let(:platform_name_map_json) do
      <<-E
{
    "el" : "Enterprise Linux",
    "debian" : "Debian",
    "mac_os_x" : "OS X",
    "ubuntu" : "Ubuntu",
    "solaris2" : "Solaris",
    "sles" : "SUSE Enterprise",
    "suse" : "openSUSE",
    "windows" : "Windows"
}
E
    end

    let(:platform_name_map) do
      JSON.parse(platform_name_map_json)
    end

    let(:directory_contents) do
      %w[
        build_os=centos-5,machine_architecture=x64,role=oss-builder/pkg/demoproject-10.22.0-1.el5.x86_64.rpm.metadata.json
        build_os=centos-5,machine_architecture=x64,role=oss-builder/pkg/demoproject-10.22.0-1.el5.x86_64.rpm
        build_os=centos-5,machine_architecture=x64,role=oss-builder/pkg/BUILD_VERSION
        build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/demoproject-10.22.0-1.el5.i686.rpm.metadata.json
        build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/demoproject-10.22.0-1.el5.i686.rpm
        build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/BUILD_VERSION
      ]
    end

    let(:artifact_collection) do
      ArtifactCollection.new("demoproject", {})
    end

    it "has a project name" do
      artifact_collection.project.should == "demoproject"
    end

    it "has config" do
      artifact_collection.config.should == {}
    end

    it "loads the mapping of build platforms to install platforms from the local copy" do
      expected_path = File.expand_path("../demoproject.json", __FILE__)
      IO.should_receive(:read).with(expected_path).and_return(platform_map_json)
      artifact_collection.platform_map_json.should == platform_map_json
    end

    it "loads the mapping of platform short names to long names from the local copy" do
      expected_path = File.expand_path("../demoproject-platform-names.json", __FILE__)
      IO.should_receive(:read).with(expected_path).and_return(platform_name_map_json)
      artifact_collection.platform_name_map_json.should == platform_name_map_json
    end

    it "finds the package files among the artifacts" do
      Dir.should_receive(:[]).with("**/pkg/*").and_return(directory_contents)
      expected = %w[
        build_os=centos-5,machine_architecture=x64,role=oss-builder/pkg/demoproject-10.22.0-1.el5.x86_64.rpm
        build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/demoproject-10.22.0-1.el5.i686.rpm
      ]
      artifact_collection.package_paths.should == expected
    end

    context "after loading the build and platform mappings" do

      before do
        artifact_collection.should respond_to(:platform_map_json)
        artifact_collection.stub!(:platform_map_json).and_return(platform_map_json)
        artifact_collection.should respond_to(:platform_name_map_json)
        artifact_collection.stub!(:platform_name_map_json).and_return(platform_name_map_json)
      end

      it "parses the build platform mapping" do
        artifact_collection.platform_map.should == platform_map
      end

      it "parses the platform short name => long name mapping" do
        artifact_collection.platform_name_map.should == platform_name_map
      end

      it "returns a list of artifacts for each package" do
        Dir.should_receive(:[]).with("**/pkg/*").and_return(directory_contents)

        artifact_collection.should have(2).artifacts
        centos5_64bit_artifact = artifact_collection.artifacts.first

        path = "build_os=centos-5,machine_architecture=x64,role=oss-builder/pkg/demoproject-10.22.0-1.el5.x86_64.rpm"
        centos5_64bit_artifact.path.should == path

        platforms = [ [ "el", "5", "x86_64" ], [ "sles","11.2","x86_64" ] ]
        centos5_64bit_artifact.platforms.should == platforms
      end

      context "and some expected packages are missing" do
        let(:directory_contents) do
          %w[
            build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/demoproject-10.22.0-1.el5.i686.rpm
            build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/BUILD_VERSION
          ]
        end

        before do
          Dir.should_receive(:[]).with("**/pkg/*").and_return(directory_contents)
        end

        it "errors out verifying all packages are available" do
          err_msg = "Missing packages for config(s): 'build_os=centos-5,machine_architecture=x64,role=oss-builder'"
          lambda {artifact_collection.artifacts}.should raise_error(ArtifactCollection::MissingArtifact, err_msg)
        end

      end
    end

  end # describe ArtifactCollection

  describe Artifact do

    let(:path) { "build_os=centos-5,machine_architecture=x86,role=oss-builder/pkg/demoproject-11.4.0-1.el5.x86_64.rpm" }

    let(:content) { StringIO.new("this is the package content\n") }

    let(:md5) { "d41d8cd98f00b204e9800998ecf8427e" }

    let(:sha256) { "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" }

    let(:platforms) { [ [ "el", "5", "x86_64" ], [ "sles","11.2","x86_64" ] ] }

    let(:artifact) { Artifact.new(path, platforms, { :version => "11.4.0-1" }) }

    it "has the path to the package" do
      artifact.path.should == path
    end

    it "has a list of platforms the package supports" do
      artifact.platforms.should == platforms
    end

    it "generates a MD5 of an artifact" do
      File.should_receive(:open).with(path).and_return(content)
      artifact.md5.should == md5
    end

    it "generates a SHA256 of an artifact" do
      File.should_receive(:open).with(path).and_return(content)
      artifact.sha256.should == sha256
    end

    it "adds the package to a release manifest" do
      expected = {
        "el" => {
          "5" => { "x86_64" => { "11.4.0-1" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm" } }
        },
        "sles" => {
          "11.2" => { "x86_64" => { "11.4.0-1" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm" } }
        }
      }

      manifest = artifact.add_to_release_manifest!({})
      manifest.should == expected
    end

    it "adds the package to a v2 release manifest" do
      File.should_receive(:open).with(path).twice.and_return(content)
      expected = {
        "el" => {
          "5" => { "x86_64" => { "11.4.0-1" => {
            "relpath" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm",
            "md5" => md5,
            "sha256" => sha256
              }
            }
          }
        },
        "sles" => {
          "11.2" => { "x86_64" => { "11.4.0-1" => {
            "relpath" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm",
            "md5" => md5,
            "sha256" => sha256
              }
            }
          }
        }
      }
      v2_manifest = artifact.add_to_v2_release_manifest!({})
      v2_manifest.should == expected
    end

  end
end

