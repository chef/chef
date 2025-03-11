#!/usr/bin/env ruby

require 'artifactory'
require 'fileutils'
require 'rubygems/commands/push_command'

def self.env_or_empty(key)
  ENV[key] || ''
end

def self.env_or_raise(key)
  ENV[key] || raise("Required ENV variable `#{key}` is unset!")
end

project_name = env_or_raise('PROJECT_NAME')
artifactory_endpoint = env_or_raise('ARTIFACTORY_ENDPOINT')

# This publishes the chef gem to artifactory
if (project_name == 'chef') && (ENV['ADHOC'] != 'true')
  GEM_PACKAGE_PATTERN = '**/pkg/[^/]*\.gem'.freeze
  gem_base_name = project_name

  project_source = File.expand_path(__FILE__ + '/../../..')

  gems_found = Dir.glob("#{project_source}/#{GEM_PACKAGE_PATTERN}")

  # Sometimes there are multiple copies of a gem on disk -- only upload one copy.
  gems_to_publish = gems_found.uniq { |gem| File.basename(gem) }

  puts "Publishing Gems from #{project_source}"
  puts ''

  gems_to_publish.each do |gem_path|
    puts 'Publishing gem ' + gem_path
    upload_path = "#{artifactory_endpoint}/api/gems/omnibus-gems-local"
    # This mimics the behavior of the gem command line, and is a public api:
    # http://docs.seattlerb.org/rubygems/Gem/Command.html
    gem_pusher = Gem::Commands::PushCommand.new
    gem_pusher.handle_options [gem_path, '--host', upload_path, '--verbose']
    gem_pusher.execute
  end
end
