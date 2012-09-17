#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'optparse'
require 'mixlib/shellout'

STDOUT.sync = true
# bump mixlib-shellout's default timeout to 20 minutes
# and stream output from forked process
shellout_opts = {:timeout => 1200, :live_stream => STDOUT}

#
# Usage: release.sh --project PROJECT --version VERSION --bucket BUCKET
#

options = {}
optparse = OptionParser.new do |opts|
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
end

begin
  optparse.parse!
  required = [:project, :version, :bucket]
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

build_support_file = File.join(File.dirname(__FILE__), "#{options[:project]}.json")

if File.exists?(build_support_file)
  jenkins_build_support = JSON.load(IO.read(build_support_file))
else
  error_msg = "Could not locate build support file for %s at %s."
  raise error_msg % [options[:project], File.expand_path(build_support_file)]
end

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
  build_location = "/#{build_platform.join('/')}/#{build_package.split('/').last}"
  puts "UPLOAD: #{build_package} -> #{build_location}"

  s3_cmd = ["s3cmd",
            "put",
            "--progress",
            "--acl-public",
            build_package,
            "s3://#{options[:bucket]}#{build_location}"].join(" ")
  shell = Mixlib::ShellOut.new(s3_cmd, shellout_opts)
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

s3_location = "s3://#{options[:bucket]}/#{options[:project]}-platform-support/#{options[:version]}.json"
puts "UPLOAD: platform-support.json -> #{s3_location}"
s3_cmd = ["s3cmd",
          "put",
          "platform-support.json",
          s3_location].join(" ")
shell = Mixlib::ShellOut.new(s3_cmd, shellout_opts)
shell.run_command
shell.error!

###############################################################################
# BACKWARD COMPAT HACK
#
# TODO: DELETE EVERYTHING BELOW THIS COMMENT WHEN UPDATED OMNITRUCK IS LIVE
#
# See https://github.com/opscode/omnibus-chef/pull/12#issuecomment-8572411
# for more info.
###############################################################################
if options[:project] == 'chef'
  s3_location = "s3://#{options[:bucket]}/platform-support/#{options[:version]}.json"
  puts "UPLOAD: platform-support.json -> #{s3_location}"
  s3_cmd = ["s3cmd",
            "put",
            "platform-support.json",
            s3_location].join(" ")
  shell = Mixlib::ShellOut.new(s3_cmd, shellout_opts)
  shell.run_command
  shell.error!
end
