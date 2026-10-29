#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: 2012, Brightcove, Inc
#
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

require_relative "../resource"

class Chef
  class Resource
    class UserUlimit < Chef::Resource

      provides :user_ulimit, target_mode: true
      target_mode support: :full

      description "Use the **user_ulimit** resource to create individual ulimit files that are installed into the `/etc/security/limits.d/` directory. On Solaris, which has no PAM `limits.d` concept, a subset of the properties are instead applied as resource controls (rctls) on a `project(4)` entry via `projadd`/`projmod`."
      introduced "16.0"
      examples <<~DOC
      **Set filehandle limit for the tomcat user**:

      ```ruby
      user_ulimit 'tomcat' do
        filehandle_limit 8192
      end
      ```

      **Specify a username that differs from the name given to the resource block**:

      ```ruby
      user_ulimit 'Bump filehandle limits for tomcat user' do
        username 'tomcat'
        filehandle_limit 8192
      end
      ```

      **Set filehandle limit for the tomcat user with a non-default filename**:

      ```ruby
      user_ulimit 'tomcat' do
        filehandle_limit 8192
        filename 'tomcat_filehandle_limits.conf'
      end
      ```
      DOC

      # Maps the subset of this resource's ulimit properties that have a direct,
      # confirmed Solaris project(4) resource control (rctl) equivalent. Properties
      # not present in this map (for example maxlogins_limit, which is a PAM-only
      # concept with no Solaris kernel rctl equivalent) are rejected with a clear
      # error on Solaris rather than silently ignored.
      # @since 19.4.45
      SOLARIS_RCTL_MAP = {
        "as" => "process.max-address-space",
        "virt" => "process.max-address-space",
        "cpu" => "process.max-cpu-time",
        "filehandle" => "process.max-file-descriptor",
        "core" => "process.max-core-size",
        "stack" => "process.max-stack-size",
      }.freeze

      # ulimit properties with no supported Solaris rctl mapping. If any of these
      # are set while converging on Solaris, we raise rather than silently drop them.
      # @since 19.4.45
      SOLARIS_UNSUPPORTED_PROPERTIES = %i{
        locks_limit memory_limit
        maxlogins_limit maxlogins_soft_limit maxlogins_hard_limit
        msgqueue_limit msgqueue_soft_limit msgqueue_hard_limit
        sigpending_limit sigpending_soft_limit sigpending_hard_limit
        rss_limit rss_soft_limit rss_hard_limit
        rtprio_limit rtprio_soft_limit rtprio_hard_limit
        process_limit process_soft_limit process_hard_limit
      }.freeze

      property :username, String, name_property: true
      property :as_limit, [String, Integer]
      property :as_soft_limit, [String, Integer]
      property :as_hard_limit, [String, Integer]
      property :filehandle_limit, [String, Integer]
      property :filehandle_soft_limit, [String, Integer]
      property :filehandle_hard_limit, [String, Integer]
      property :process_limit, [String, Integer]
      property :process_soft_limit, [String, Integer]
      property :process_hard_limit, [String, Integer]
      property :locks_limit, [String, Integer]
      property :memory_limit, [String, Integer]
      property :maxlogins_limit, [String, Integer]
      property :maxlogins_soft_limit, [String, Integer]
      property :maxlogins_hard_limit, [String, Integer]
      property :msgqueue_limit, [String, Integer]
      property :msgqueue_soft_limit, [String, Integer]
      property :msgqueue_hard_limit, [String, Integer]
      property :core_limit, [String, Integer]
      property :core_soft_limit, [String, Integer]
      property :core_hard_limit, [String, Integer]
      property :cpu_limit, [String, Integer]
      property :cpu_soft_limit, [String, Integer]
      property :cpu_hard_limit, [String, Integer]
      property :sigpending_limit, [String, Integer]
      property :sigpending_soft_limit, [String, Integer]
      property :sigpending_hard_limit, [String, Integer]
      property :stack_limit, [String, Integer]
      property :stack_soft_limit, [String, Integer]
      property :stack_hard_limit, [String, Integer]
      property :rss_limit, [String, Integer]
      property :rss_soft_limit, [String, Integer]
      property :rss_hard_limit, [String, Integer]
      property :rtprio_limit, [String, Integer]
      property :rtprio_soft_limit, [String, Integer]
      property :rtprio_hard_limit, [String, Integer]
      property :virt_limit, [String, Integer]
      property :filename, String,
               coerce: proc { |m| m.end_with?(".conf") ? m : m + ".conf" },
               default: lazy { |r| r.username == "*" ? "00_all_limits.conf" : "#{r.username}_limits.conf" }

      # Name of the Solaris project(4) entry this resource manages for the given user.
      # @since 19.4.45
      def solaris_project_name
        "user.#{username}"
      end

      # Whether the named Solaris project already exists in /etc/project.
      # @since 19.4.45
      def solaris_project_exists?(project_name)
        ::TargetIO::File.read("/etc/project").each_line.any? { |line| line.start_with?("#{project_name}:") }
      rescue Errno::ENOENT
        false
      end

      # Whether every required "(privilege,value,deny)" rctl clause is already present
      # for the given project/rctl pair in /etc/project.
      # @since 19.4.45
      def solaris_rctl_set?(project_name, required_clauses)
        line = ::TargetIO::File.read("/etc/project").each_line.find { |l| l.start_with?("#{project_name}:") }
        return false unless line

        required_clauses.all? { |clause| line.include?(clause) }
      rescue Errno::ENOENT
        false
      end

      # Builds the list of "(basic,value,deny)" / "(privileged,value,deny)" clauses for
      # a single rctl from this resource's unsuffixed/soft/hard properties. An unsuffixed
      # value sets both the basic (soft) and privileged (hard) limits, matching the
      # semantics of the existing ulimit.erb template used on non-Solaris platforms.
      # @since 19.4.45
      def solaris_rctl_clauses(value, soft, hard)
        if value
          ["(basic,#{value},deny)", "(privileged,#{value},deny)"]
        else
          clauses = []
          clauses << "(basic,#{soft},deny)" if soft
          clauses << "(privileged,#{hard},deny)" if hard
          clauses
        end
      end

      # Chef Infra Client 19 ships only as a Habitat package, and Habitat does
      # not build for Solaris, so there is no native/local-mode Chef 19
      # install on Solaris -- this resource's Solaris support is only ever
      # reachable via Target Mode. Raises a clear error if that's not the
      # case, instead of silently behaving as if Solaris were natively
      # supported like any other platform_family branch in this resource.
      # @since 19.4.45
      def raise_unless_target_mode_for_solaris!
        return if ChefConfig::Config.target_mode?

        raise "user_ulimit's Solaris support is only available in Target Mode. Chef Infra " \
          "Client 19 has no native Solaris package (Habitat does not build for Solaris), so " \
          "Solaris can only be managed via `chef-client --target`."
      end

      # Raises if any ulimit property is set that has no supported Solaris rctl mapping.
      # @since 19.4.45
      def raise_if_unsupported_solaris_properties!
        unsupported = SOLARIS_UNSUPPORTED_PROPERTIES.select { |p| !send(p).nil? }
        return if unsupported.empty?

        raise Chef::Exceptions::UnsupportedAction,
          "user_ulimit on Solaris does not support: #{unsupported.join(", ")}. These map to " \
          "concepts (PAM maxlogins, POSIX message queues, file locks, memlock, process/LWP " \
          "counts, or real-time priority) that have no direct Solaris project(4) resource " \
          "control equivalent. Supported properties on Solaris are: as_limit/virt_limit, " \
          "cpu_limit, filehandle_limit, core_limit, stack_limit (and their _soft_limit / " \
          "_hard_limit variants)."
      end

      action :create, description: "Create a ulimit configuration file." do
        if node["platform_family"] == "solaris2"
          raise_unless_target_mode_for_solaris!
          raise_if_unsupported_solaris_properties!
          project_name = solaris_project_name

          execute "create Solaris project #{project_name}" do
            command ["projadd", "-U", new_resource.username, project_name]
            not_if { solaris_project_exists?(project_name) }
          end

          SOLARIS_RCTL_MAP.each do |base, rctl|
            next if base == "virt" && !new_resource.as_limit.nil?

            value = base == "virt" ? new_resource.virt_limit : new_resource.send(:"#{base}_limit")
            soft = new_resource.respond_to?(:"#{base}_soft_limit") ? new_resource.send(:"#{base}_soft_limit") : nil
            hard = new_resource.respond_to?(:"#{base}_hard_limit") ? new_resource.send(:"#{base}_hard_limit") : nil

            clauses = solaris_rctl_clauses(value, soft, hard)
            next if clauses.empty?

            execute "set #{rctl} for #{project_name}" do
              command ["projmod", "-s", "-K", "#{rctl}=#{clauses.join(",")}", project_name]
              not_if { solaris_rctl_set?(project_name, clauses) }
            end
          end
        else
          template "/etc/security/limits.d/#{new_resource.filename}" do
            source ::File.expand_path("support/ulimit.erb", __dir__)
            local true
            mode "0644"
            sensitive new_resource.sensitive
            variables(
              ulimit_user: new_resource.username,
              as_limit: new_resource.as_limit,
              as_soft_limit: new_resource.as_soft_limit,
              as_hard_limit: new_resource.as_hard_limit,
              filehandle_limit: new_resource.filehandle_limit,
              filehandle_soft_limit: new_resource.filehandle_soft_limit,
              filehandle_hard_limit: new_resource.filehandle_hard_limit,
              process_limit: new_resource.process_limit,
              process_soft_limit: new_resource.process_soft_limit,
              process_hard_limit: new_resource.process_hard_limit,
              locks_limit: new_resource.locks_limit,
              memory_limit: new_resource.memory_limit,
              maxlogins_limit: new_resource.maxlogins_limit,
              maxlogins_soft_limit: new_resource.maxlogins_soft_limit,
              maxlogins_hard_limit: new_resource.maxlogins_hard_limit,
              msgqueue_limit: new_resource.msgqueue_limit,
              msgqueue_soft_limit: new_resource.msgqueue_soft_limit,
              msgqueue_hard_limit: new_resource.msgqueue_hard_limit,
              core_limit: new_resource.core_limit,
              core_soft_limit: new_resource.core_soft_limit,
              core_hard_limit: new_resource.core_hard_limit,
              cpu_limit: new_resource.cpu_limit,
              cpu_soft_limit: new_resource.cpu_soft_limit,
              cpu_hard_limit: new_resource.cpu_hard_limit,
              sigpending_limit: new_resource.sigpending_limit,
              sigpending_soft_limit: new_resource.sigpending_soft_limit,
              sigpending_hard_limit: new_resource.sigpending_hard_limit,
              stack_limit: new_resource.stack_limit,
              stack_soft_limit: new_resource.stack_soft_limit,
              stack_hard_limit: new_resource.stack_hard_limit,
              rss_limit: new_resource.rss_limit,
              rss_soft_limit: new_resource.rss_soft_limit,
              rss_hard_limit: new_resource.rss_hard_limit,
              rtprio_limit: new_resource.rtprio_limit,
              rtprio_soft_limit: new_resource.rtprio_soft_limit,
              rtprio_hard_limit: new_resource.rtprio_hard_limit,
              virt_limit: new_resource.virt_limit
            )
          end
        end
      end

      action :delete, description: "Delete an existing ulimit configuration file." do
        if node["platform_family"] == "solaris2"
          raise_unless_target_mode_for_solaris!
          project_name = solaris_project_name

          execute "delete Solaris project #{project_name}" do
            command ["projdel", project_name]
            only_if { solaris_project_exists?(project_name) }
          end
        else
          file "/etc/security/limits.d/#{new_resource.filename}" do
            action :delete
          end
        end
      end
    end
  end
end
