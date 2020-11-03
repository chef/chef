# Author:: Stephan Renatus <srenatus@chef.io>
# Copyright:: (c) 2016-2019, Chef Software Inc. <legal@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Chef
  module Audit
    module DefaultAttributes
      DEFAULTS = {
        # Controls the inspec gem version to install and execution. Example values: '1.1.0', 'latest'
        # Starting with Chef Infra Client 15, only the embedded InSpec gem can be used and this attribute will be ignored
        "inspec_version" => nil,

        # sets URI to alternate gem source
        # example values: nil, 'https://mygem.server.com'
        # notes: the root of the URL must host the *specs.4.8.gz source index
        "inspec_gem_source" => nil,

        # If enabled, a cache is built for all backend calls. This should only be
        # disabled if you are expecting unique results from the same backend call.
        "inspec_backend_cache" => true,

        # controls where inspec scan reports are sent
        # possible values: 'chef-server-automate', 'chef-automate', 'json-file'
        # notes: 'chef-automate' requires inspec version 0.27.1 or greater
        # deprecated: 'chef-visibility' is replaced with 'chef-automate'
        # deprecated: 'chef-compliance' is replaced with 'chef-automate'
        # deprecated: 'chef-server-visibility' is replaced with 'chef-server-automate'
        "reporter" => "json-file",

        # controls where inspec profiles are fetched from, Chef Automate or via Chef Server
        # possible values: nil, 'chef-server', 'chef-automate'
        "fetcher" => nil,

        # allow for connections to HTTPS endpoints using self-signed ssl certificates
        "insecure" => nil,

        # Optional for 'chef-server-automate' reporter
        # defaults to Chef Server org if not defined
        "owner" => nil,

        # raise exception if Automate API endpoint is unreachable
        # while fetching profiles or posting a report
        "raise_if_unreachable" => true,

        # fail converge if downloaded profile is not present
        # https://github.com/chef-cookbooks/audit/issues/166
        "fail_if_not_present" => false,

        "interval" => {
          # control how often inspec scans are run, if not on every node converge
          # notes: false value will result in running inspec scan every converge
          "enabled" => false,

          # controls how often inspec scans are run (in minutes)
          # notes: only used if interval is enabled above
          "time" => 1440,
        },

        # controls verbosity of inspec runner
        "quiet" => true,

        # Chef Inspec Compliance profiles to be used for scan of node
        # See README.md for details
        "profiles" => {},

        # Attributes used to run the given profiles
        "attributes" => {},

        # Set this to false if you don't want ['audit']['attributes'] to be saved in the node object and stored in Chef Server or Automate. Useful if you are passing sensitive data to the inspec profile via the attributes.
        "attributes_save" => true,

        # If enabled, a hash of the Chef "node" object will be sent to InSpec in an attribute
        # named `chef_node`
        "chef_node_attribute_enabled" => false,

        # Set this to the path of a YAML waiver file you wish to apply
        # See https://www.inspec.io/docs/reference/waivers/
        "waiver_file" => nil,

        "json_file" => {
          # The location of the json-file output:
          # <chef_cache_path>/cookbooks/audit/inspec-<YYYYMMDDHHMMSS>.json
          # TODO: ^^ comment is wrong
          # TODO: Does this path work?
          "location" => File.expand_path(Time.now.utc.strftime("../../../inspec-%Y%m%d%H%M%S.json"), __dir__),
        },

        # Control results that have a `run_time` below this limit will
        # be stripped of the `start_time` and `run_time` fields to
        # reduce the size of the reports being sent to Automate
        "run_time_limit" => 1.0,

        # A control result message that exceeds this character limit will be truncated.
        # This helps keep reports to a reasonable size. On rare occasions, we've seen messages exceeding 9 MB in size,
        # causing the report to not be ingested in the backend because of the 4 MB report size rpc limitation.
        # InSpec will append this text at the end of any truncated messages: `[Truncated to 10000 characters]`
        # Requires InSpec 4.18.114 or newer (bundled with Chef Infra Client starting with version 16.0.303)
        "result_message_limit" => 10000,

        # When an InSpec resource throws an exception (e.g. permission denied), results will contain a short error message and a
        # detailed ruby stacktrace of the error. This attribute instructs InSpec not to include the detailed stacktrace in order
        # to keep the overall report to a manageable size.
        # Requires InSpec 4.18.114 or newer (bundled with Chef Infra Client starting with version 16.0.303)
        "result_include_backtrace" => false,

        # The array of results per control will be truncated at this limit to avoid large reports that cannot be
        # processed by Automate. A summary of removed results will be sent with each impacted control.
        "control_results_limit" => 50,
      }.freeze
    end
  end
end
