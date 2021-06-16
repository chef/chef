require "uri" unless defined?(URI)
require "plugins/inspec-compliance/lib/inspec-compliance"

class Chef
  module Compliance
    module Fetcher
      class Automate < ::InspecPlugins::Compliance::Fetcher
        name "chef-automate"

        # Positions this fetcher before Chef InSpec's `compliance` fetcher.
        # Only load this file if you want to use Compliance Phase in Chef Solo with Chef Automate.
        priority 502

        CONFIG = {
          "insecure" => true,
          "token" => nil,
          "server_type" => "automate",
          "automate" => {
            "ent" => "default",
            "token_type" => "dctoken",
          },
        }.freeze

        def self.resolve(target)
          uri = get_target_uri(target)
          return nil if uri.nil?

          config = CONFIG.dup

          # we have detailed information available in our lockfile, no need to ask the server
          if target.respond_to?(:key?) && target.key?(:url)
            profile_fetch_url = target[:url]
          else
            # verifies that the target e.g base/ssh exists
            profile = sanitize_profile_name(uri)
            owner, id = profile.split("/")
            profile_path = if target.respond_to?(:key?) && target.key?(:version)
                             "/compliance/profiles/#{owner}/#{id}/version/#{target[:version]}/tar"
                           else
                             "/compliance/profiles/#{owner}/#{id}/tar"
                           end

            url = URI(Chef::Config[:data_collector][:server_url])
            url.path = profile_path
            profile_fetch_url = url.to_s

            config["token"] = Chef::Config[:data_collector][:token]

          end

          new(profile_fetch_url, config)
        rescue URI::Error => _e
          nil
        end

        # returns a parsed url for `admin/profile` or `compliance://admin/profile`
        # TODO: remove in future, copied from inspec to support older versions of inspec
        def self.sanitize_profile_name(profile)
          uri = if URI(profile).scheme == "compliance"
                  URI(profile)
                else
                  URI("compliance://#{profile}")
                end
          uri.to_s.sub(%r{^compliance:\/\/}, "")
        end

        def to_s
          "#{ChefUtils::Dist::Automate::PRODUCT} for #{ChefUtils::Dist::Solo::PRODUCT} Fetcher"
        end
      end
    end
  end
end
