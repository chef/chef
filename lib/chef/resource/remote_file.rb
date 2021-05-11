#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "uri" unless defined?(URI)
require_relative "file"
require_relative "../provider/remote_file"
require_relative "../mixin/securable"
require_relative "../mixin/uris"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class RemoteFile < Chef::Resource::File
      include Chef::Mixin::Securable
      unified_mode true

      provides :remote_file

      description "Use the **remote_file** resource to transfer a file from a remote location using file specificity. This resource is similar to the **file** resource. Note: Fetching files from the `files/` directory in a cookbook should be done with the **cookbook_file** resource."

      def initialize(name, run_context = nil)
        super
        @source = []
      end

      # source can take any of the following as arguments
      # - A single string argument
      # - Multiple string arguments
      # - An array or strings
      # - A delayed evaluator that evaluates to a string
      #   or array of strings
      # All strings must be parsable as URIs.
      # source returns an array of strings.
      def source(*args)
        arg = parse_source_args(args)
        ret = set_or_return(:source,
          arg,
          { callbacks: {
              validate_source: method(:validate_source),
            } })
        if ret.is_a? String
          Array(ret)
        else
          ret
        end
      end

      def parse_source_args(args)
        if args.empty?
          nil
        elsif args[0].is_a?(Chef::DelayedEvaluator) && args.count == 1
          args[0]
        elsif args.any? { |a| a.is_a?(Chef::DelayedEvaluator) } && args.count > 1
          raise Exceptions::InvalidRemoteFileURI, "Only 1 source argument allowed when using a lazy evaluator"
        else
          Array(args).flatten
        end
      end

      property :checksum, String,
        description: "Optional, see `use_conditional_get`. The SHA-256 checksum of the file. Use to prevent a file from being re-downloaded. When the local file matches the checksum, #{ChefUtils::Dist::Infra::PRODUCT} does not download it."

      # Disable or enable ETag and Last Modified conditional GET. Equivalent to
      #   use_etag(true_or_false)
      #   use_last_modified(true_or_false)
      def use_conditional_get(true_or_false)
        use_etag(true_or_false)
        use_last_modified(true_or_false)
      end

      property :use_etag, [ TrueClass, FalseClass ], default: true,
        description: "Enable ETag headers. Set to false to disable ETag headers. To use this setting, `use_conditional_get` must also be set to true."

      alias :use_etags :use_etag

      property :use_last_modified, [ TrueClass, FalseClass ], default: true,
        description: "Enable `If-Modified-Since` headers. Set to `false` to disable `If-Modified-Since` headers. To use this setting, `use_conditional_get` must also be set to `true`."

      property :ftp_active_mode, [ TrueClass, FalseClass ], default: false,
        description: "Whether #{ChefUtils::Dist::Infra::PRODUCT} uses active or passive FTP. Set to `true` to use active FTP."

      property :headers, Hash, default: {},
        description: "A Hash of custom HTTP headers."

      property :show_progress, [ TrueClass, FalseClass ], default: false

      property :ssl_verify_mode, Symbol, equal_to: %i{verify_none verify_peer},
        introduced: "16.2",
        description: "Optional property to override SSL policy. If not specified, uses the SSL policy from `config.rb`."

      property :remote_user, String,
        introduced: "13.4",
        description: '**Windows only** The name of a user with access to the remote file specified by the source property. The user name may optionally be specified with a domain, such as: `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN) format. The domain may also be set using the `remote_domain` property. Note that this property is ignored if source is not a UNC path. If this property is specified, the `remote_password` property is required.'

      property :remote_domain, String,
        introduced: "13.4",
        description: "**Windows only** The domain of the user specified by the `remote_user` property. By default the resource will authenticate against the domain of the remote system, or as a local account if the remote system is not joined to a domain. If the remote system is not part of a domain, it is necessary to authenticate as a local user on the remote system by setting the domain to `.`, for example: remote_domain '.'. The domain may also be specified as part of the `remote_user` property."

      property :remote_password, String, sensitive: true,
        introduced: "13.4",
        description: "**Windows only** The password of the user specified by the `remote_user` property. This property is required if `remote_user` is specified and may only be specified if `remote_user` is specified. The `sensitive` property for this resource will automatically be set to `true` if `remote_password` is specified."

      property :authentication, Symbol, equal_to: %i{remote local}, default: :remote

      def after_created
        validate_identity_platform(remote_user, remote_password, remote_domain)
        identity = qualify_user(remote_user, remote_password, remote_domain)
        remote_domain(identity[:domain])
        remote_user(identity[:user])
      end

      def validate_identity_platform(specified_user, password = nil, specified_domain = nil)
        if windows?
          if specified_user && password.nil?
            raise ArgumentError, "A value for `remote_password` must be specified when a value for `user` is specified on the Windows platform"
          end
        end
      end

      def qualify_user(specified_user, password = nil, specified_domain = nil)
        domain = specified_domain
        user = specified_user

        if specified_user.nil? && ! specified_domain.nil?
          raise ArgumentError, "The domain `#{specified_domain}` was specified, but no user name was given"
        end

        # if domain is provided in both username and domain
        if specified_user && ((specified_user.include? "\\") || (specified_user.include? "@")) && specified_domain
          raise ArgumentError, "The domain is provided twice. Username: `#{specified_user}`, Domain: `#{specified_domain}`. Please specify domain only once."
        end

        if ! specified_user.nil? && specified_domain.nil?
          # Splitting username of format: Domain\Username
          domain_and_user = user.split("\\")

          if domain_and_user.length == 2
            domain = domain_and_user[0]
            user = domain_and_user[1]
          elsif domain_and_user.length == 1
            # Splitting username of format: Username@Domain
            domain_and_user = user.split("@")
            if domain_and_user.length == 2
              domain = domain_and_user[1]
              user = domain_and_user[0]
            elsif domain_and_user.length != 1
              raise ArgumentError, "The specified user name `#{user}` is not a syntactically valid user name"
            end
          end
        end

        if ( password || domain ) && user.nil?
          raise ArgumentError, "A value for `password` or `domain` was specified without specification of a value for `user`"
        end

        { domain: domain, user: user }
      end

      private

      include Chef::Mixin::Uris

      def validate_source(source)
        source = Array(source).flatten
        raise ArgumentError, "#{resource_name} has an empty source" if source.empty?

        source.each do |src|
          unless absolute_uri?(src)
            raise Exceptions::InvalidRemoteFileURI,
              "#{src.inspect} is not a valid `source` parameter for #{resource_name}. `source` must be an absolute URI or an array of URIs."
          end
        end
        true
      end

      def absolute_uri?(source)
        Chef::Provider::RemoteFile::Fetcher.network_share?(source) || (source.is_a?(String) && as_uri(source).absolute?)
      rescue URI::InvalidURIError
        false
      end

    end
  end
end
