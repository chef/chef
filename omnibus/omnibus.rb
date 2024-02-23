#
# This file is used to configure the Chef Infra Client project. It contains
# some minimal configuration examples for working with Omnibus. For a full list
# of configurable options, please see the documentation for +omnibus/config.rb+.
#

# Build internally
# ------------------------------
# By default, Omnibus uses system folders (like +/var+ and +/opt+) to build and
# cache components. If you would to build everything internally, you can
# uncomment the following options. This will prevent the need for root
# permissions in most cases.
#
# Uncomment this line to change the default base directory to "local"
# -------------------------------------------------------------------
# base_dir './local'
#
# Alternatively you can tune the individual values
# ------------------------------------------------
# cache_dir     './local/omnibus/cache'
# git_cache_dir './local/omnibus/cache/git_cache'
# source_dir    './local/omnibus/src'
# build_dir     './local/omnibus/build'
# package_dir   './local/omnibus/pkg'
# package_tmp   './local/omnibus/pkg-tmp'

# Windows architecture defaults - set to x86 unless otherwise specified.
# ------------------------------
env_omnibus_windows_arch = (ENV["OMNIBUS_WINDOWS_ARCH"] || "").downcase
env_omnibus_windows_arch = :x86 unless %w{x86 x64}.include?(env_omnibus_windows_arch)

windows_arch env_omnibus_windows_arch

use_git_caching true

# Enable S3 asset caching
# ------------------------------
use_s3_caching ENV.fetch("OMNIBUS_USE_S3_CACHING", false)
s3_access_key  ENV["AWS_ACCESS_KEY_ID"]
s3_secret_key  ENV["AWS_SECRET_ACCESS_KEY"]
s3_bucket      "opscode-omnibus-cache"

build_retries 3
fetcher_retries 3
fetcher_read_timeout 120

# Load additional software
# ------------------------------
# software_gems ['omnibus-software', 'my-company-software']
# local_software_dirs ['/path/to/local/software']

fatal_transitive_dependency_licensing_warnings true
fips_mode (ENV["OMNIBUS_FIPS_MODE"] || "").casecmp("true") >= 0


#PATCH_OMNIBUS_BUILDER=false
unless defined? PATCH_OMNIBUS_BUILDER
  PATCH_OMNIBUS_BUILDER=true
  class Omnibus::Builder
    def shellout!(command_string, options = {})
      puts "Running command: #{command_string}"
      puts "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      puts "Options: #{options.inspect}"
      puts "ENV: #{ENV.inspect}"

      # Make sure the PWD is set to the correct directory
      # Also make a clone of options so that we can mangle it safely below.
      options = { cwd: software.project_dir }.merge(options)

      # Set the log level to :info so users will see build commands
      options[:log_level] ||= :info

      # Set the live stream to :debug so users will see build output
      options[:live_stream] ||= log.live_stream(:debug)

      if command_string.include?('win32/Makefile.gcc')
        require 'fileutils'
        debug_lines=<<~DEBUGLINES
          echo $(info ************  PRINTING ENV VARIABLES ************ )
          $(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))
          echo $(info ************  END OF VARS ************************)
          make -v
          mount
        DEBUGLINES

        newfile=File.join(options[:cwd], "win32", "Makefile.gcc.new")
        origfile=File.join(options[:cwd], "win32", "Makefile.gcc")
        savefile=File.join(options[:cwd], "win32", "Makefile.gcc.save")

        unless File.exist?(savefile)
          File.open(newfile, "wt") do |of|
            File.open(origfile, "rt") do |f|
              f.each_line do |input_line|
                of.puts input_line
                if input_line =~ /^install:/
                  debug_lines.each_line do |line|
                    of.puts "\t#{line}"
                  end
                end
              end
            end
          end
          FileUtils.move(origfile, savefile)
          FileUtils.move(newfile, origfile)
        end
      end
      # Use Util's shellout
      super(command_string, **options)
    end
  end
end
