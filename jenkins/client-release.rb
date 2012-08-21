#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'optparse'
require 'mixlib/shellout'

#
# Usage: client-release.sh --version VERSION --bucket BUCKET
#

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-v", "--version VERSION", "the version of the chef installer to release") do |version|
    options[:version] = version
  end

  opts.on("-b", "--bucket S3_BUCKET_NAME", "the name of the s3 bucket to release to") do |bucket|
    options[:bucket] = bucket
  end
end

begin
  optparse.parse!
  required = [:version, :bucket]
  missing = required.select {|param| options[param].nil?}
  if !missing.empty?
    puts "Missing required options: #{missing.join(', ')}"
    puts optparse
    exit 1
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit 1
end

#
# == Jenkins Build Support Matrix
#
# :key:   - the jenkins build name
# :value: - an Array of Arrays indicating the builds supported by the
#           build. by convention, the first element in the array
#           references the build itself.
#

jenkins_build_support = {
  "build_os=centos-5,machine_architecture=x64,role=oss-builder" => [["el", "5", "x86_64"]],
  "build_os=centos-5,machine_architecture=x86,role=oss-builder" => [["el", "5", "i686"]],
  "build_os=centos-6,machine_architecture=x64,role=oss-builder" => [["el", "6", "x86_64"]],
  "build_os=centos-6,machine_architecture=x86,role=oss-builder" => [["el", "6", "i686"]],
  "build_os=debian-6,machine_architecture=x64,role=oss-builder" => [["debian", "6", "x86_64"]],
  "build_os=debian-6,machine_architecture=x86,role=oss-builder" => [["debian", "6", "i686"]],
  "build_os=mac_os_x_10_6,machine_architecture=x64,role=oss-builder" => [["mac_os_x", "10.6", "x86_64"]],
  "build_os=mac_os_x_10_7,machine_architecture=x64,role=oss-builder" => [["mac_os_x", "10.7", "x86_64"]],
  "build_os=solaris-10,machine_architecture=intel,role=oss-builder" =>
  [
   ["solaris", "10", "i386"],
   ["solaris", "11", "i386"]
  ],
  "build_os=solaris-9,machine_architecture=sparc,role=oss-builder" =>
  [
   ["solaris", "9", "sparc"],
   ["solaris", "10", "sparc"],
   ["solaris", "11", "sparc"]
  ],
  "build_os=ubuntu-10-04,machine_architecture=x64,role=oss-builder" =>
  [
   ["ubuntu", "10.04", "x86_64"],
   ["ubuntu", "10.10", "x86_64"]
  ],
  "build_os=ubuntu-10-04,machine_architecture=x86,role=oss-builder" =>
  [
   ["ubuntu", "10.04", "i686"],
   ["ubuntu", "10.10", "i686"]
  ],
  "build_os=ubuntu-11-04,machine_architecture=x64,role=oss-builder" =>
  [
   ["ubuntu", "11.04", "x86_64"],
   ["ubuntu", "11.10", "x86_64"],
   ["ubuntu", "12.04", "x86_64"]
  ],
  "build_os=ubuntu-11-04,machine_architecture=x86,role=oss-builder" =>
  [
   ["ubuntu", "11.04", "i686"],
   ["ubuntu", "11.10", "i686"],
   ["ubuntu", "12.04", "i686"]
  ]
}

# fetch the list of local packages
local_packages = Dir['**/pkg/*']

# generate json
build_support_json = {}
jenkins_build_support.each do |(build, supported_platforms)|
  build_platform = supported_platforms.first

  # find the build in the local packages
  build_package = local_packages.find {|b| b.include?(build)}
  raise unless build_package

  # upload build to build platform directory
  build_location = "/#{options[:bucket]}/#{build_platform.join('/')}/#{build_package.split('/').last}"
  puts "UPLOAD: #{build_package} -> #{build_location}"

  s3_cmd = ["s3cmd", "put", "--acl-public", build_package, "s3:/#{build_location}"].join(" ")
  shell = Mixlib::ShellOut.new(s3_cmd)
  shell.run_command
  shell.error!

  # update json with build information
  supported_platforms.each do |(platform, platform_version, machine_architecture)|
    build_support_json[platform] ||= {}
    build_support_json[platform][platform_version] ||= {}
    build_support_json[platform][platform_version][machine_architecture] = {}
    build_support_json[platform][platform_version][machine_architecture][options[:version]] = build_location
  end
end

File.open("platform-support.json", "w") {|f| f.puts JSON.pretty_generate(build_support_json)}

s3_location = "s3://#{options[:bucket]}/platform-support/#{options[:version]}.json"
puts "UPLOAD: platform-support.json -> #{s3_location}"
s3_cmd = ["s3cmd",
          "put",
          "platform-support.json",
          s3_location].join(" ")
shell = Mixlib::ShellOut.new(s3_cmd)
shell.run_command
shell.error!
