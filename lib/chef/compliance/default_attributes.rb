# Author:: Stephan Renatus <srenatus@chef.io>
# Copyright:: Copyright (c) Chef Software Inc. <legal@chef.io>
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

require "chef/node/attribute_collections" # for VividMash
require "chef/util/path_helper"

class Chef
  module Compliance
    DEFAULT_ATTRIBUTES = Chef::Node::VividMash.new(
      # If enabled, a cache is built for all backend calls. This should only be
      # disabled if you are expecting unique results from the same backend call.
      # Under the covers, this controls :command and :file caching on Chef InSpec's
      # Train connection.
      "inspec_backend_cache" => true,

      # Controls what is done with the resulting report after the Chef InSpec run.
      # Accepts a single string value or an array of multiple values.
      # Accepted values: 'chef-server-automate', 'chef-automate', 'json-file', 'audit-enforcer', 'cli'
      "reporter" => %w{json-file cli},

      # Controls if Chef InSpec profiles should be fetched from Chef Automate or Chef Infra Server
      # in addition to the default fetch locations provided by Chef Inspec.
      # Accepted values: nil, 'chef-server', 'chef-automate'
      "fetcher" => nil,

      # Allow for connections to HTTPS endpoints using self-signed ssl certificates.
      "insecure" => nil,

      # Controls verbosity of Chef InSpec runner. See less output when true.
      "quiet" => true,

      # Chef Inspec Compliance profiles to be used for scan of node.
      # See Compliance Phase documentation for further details:
      # https://docs.chef.io/chef_compliance_phase/#compliance-phase-configuration
      "profiles" => {},

      # Extra inputs passed to Chef InSpec to allow finer-grained control over behavior.
      # These are mapped to Chef InSpec's inputs, but are named attributes here for legacy reasons.
      # See Chef Inspec's documentation for more information: https://docs.chef.io/inspec/inputs/
      "attributes" => {},

      # A string path or an array of paths to Chef InSpec waiver files.
      # See Chef Inspec's documentation for more information: https://docs.chef.io/inspec/waivers/
      "waiver_file" => nil,

      "json_file" => {
        # The location on disk that Chef InSpec's json reports are saved to when using the
        # 'json-file' reporter. Defaults to:
        # <chef_cache_path>/compliance_reports/compliance-<timestamp>.json
        "location" => Chef::Util::PathHelper.join(
          Chef::Config[:cache_path],
          "compliance_reports",
          Time.now.utc.strftime("compliance-%Y%m%d%H%M%S.json")
        ),
      },

      # Control results that have a `run_time` below this limit will
      # be stripped of the `start_time` and `run_time` fields to
      # reduce the size of the reports being sent to Chef Automate.
      "run_time_limit" => 1.0,

      # A control result message that exceeds this character limit will be truncated.
      # This helps keep reports to a reasonable size. On rare occasions, we've seen messages exceeding 9 MB in size,
      # causing the report to not be ingested in the backend because of the 4 MB report size rpc limitation.
      # Chef InSpec will append this text at the end of any truncated messages: `[Truncated to 10000 characters]`
      "result_message_limit" => 10000,

      # When a Chef InSpec resource throws an exception, results will contain a short error message and a
      # detailed ruby stacktrace of the error. This attribute instructs Chef InSpec not to include the detailed stacktrace in order
      # to keep the overall report to a manageable size.
      "result_include_backtrace" => false,

      # The array of results per control will be truncated at this limit to avoid large reports that cannot be
      # processed by Chef Automate. A summary of removed results will be sent with each impacted control.
      "control_results_limit" => 50,

      # If enabled, a hash representation of the Chef Infra node object will be sent to Chef InSpec in an input
      # named `chef_node`.
      "chef_node_attribute_enabled" => false,

      # Should the built-in compliance phase run. True and false force the behavior. Nil does magic based on if you have
      # profiles defined but do not have the audit cookbook enabled.
      "compliance_phase" => false
    )
  end
end
