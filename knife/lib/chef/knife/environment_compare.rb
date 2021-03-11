#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright 2013-2016, Sander Botman.
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

require_relative "../knife"

class Chef
  class Knife
    class EnvironmentCompare < Knife

      deps do
        require "chef/environment" unless defined?(Chef::Environment)
      end

      banner "knife environment compare [ENVIRONMENT..] (options)"

      option :all,
        short: "-a",
        long: "--all",
        description: "Show all cookbooks.",
        boolean: true

      option :mismatch,
        short: "-m",
        long: "--mismatch",
        description: "Only show mismatching versions.",
        boolean: true

      def run
        # Get the commandline environments or all if none are provided.
        environments = environment_list

        # Get a list of all cookbooks that have constraints and their environment.
        constraints = constraint_list(environments)

        # Get the total list of cookbooks that have constraints
        cookbooks = cookbook_list(constraints)

        # If we cannot find any cookbooks, we can stop here.
        if cookbooks.nil? || cookbooks.empty?
          ui.error "Cannot find any environment cookbook constraints"
          exit 1
        end

        # Get all cookbooks so we can compare them all
        cookbooks = rest.get("/cookbooks?num_versions=1") if config[:all]

        # display matrix view of in the requested format.
        if config[:format] == "summary"
          matrix = matrix_output(cookbooks, constraints)
          ui.output(matrix)
        else
          ui.output(constraints)
        end
      end

      private

      def environment_list
        environments = []
        unless @name_args.nil? || @name_args.empty?
          @name_args.each { |name| environments << name }
        else
          environments = Chef::Environment.list
        end
      end

      def constraint_list(environments)
        constraints = {}
        environments.each do |env, url| # rubocop:disable Style/HashEachMethods
          # Because you cannot modify the default environment I filter it out here.
          unless env == "_default"
            envdata = Chef::Environment.load(env)
            ver = envdata.cookbook_versions
            constraints[env] = ver
          end
        end
        constraints
      end

      def cookbook_list(constraints)
        result = {}
        constraints.each_value { |cb| result.merge!(cb) }
        result
      end

      def matrix_output(cookbooks, constraints)
        rows = [ "" ]
        environments = []
        constraints.each_key { |e| environments << e.to_s }
        columns = environments.count + 1
        environments.each { |env| rows << ui.color(env, :bold) }
        cookbooks.each_key do |c|
          total = []
          environments.each { |n| total << constraints[n][c] }
          if total.uniq.count == 1
            next if config[:mismatch]

            color = :white
          else
            color = :yellow
          end
          rows << ui.color(c, :bold)
          environments.each do |e|
            tag = constraints[e][c] || "latest"
            rows << ui.color(tag, color)
          end
        end
        ui.list(rows, :uneven_columns_across, columns)
      end

    end
  end
end
