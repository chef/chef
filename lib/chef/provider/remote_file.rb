#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "file"

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File
      provides :remote_file, target_mode: true

      def initialize(new_resource, run_context)
        @content_class = Chef::Provider::RemoteFile::Content
        super
      end

      def define_resource_requirements
        [ new_resource.remote_user, new_resource.remote_domain,
          new_resource.remote_password ].each do |prop|
            requirements.assert(:all_actions) do |a|
              a.assertion do
                if prop
                  windows?
                else
                  true
                end
              end
              a.failure_message Chef::Exceptions::UnsupportedPlatform, "'remote_user', 'remote_domain' and 'remote_password' properties are supported only for Windows platform"
              a.whyrun("Assuming that the platform is Windows while passing 'remote_user', 'remote_domain' and 'remote_password' properties")
            end
          end

        super
      end

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(new_resource.name)
        super
      end

      private

      def managing_content?
        return true if new_resource.checksum
        return true if !new_resource.source.nil? && @action != :create_if_missing

        false
      end

    end
  end
end
