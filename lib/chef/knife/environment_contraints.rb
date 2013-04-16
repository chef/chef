#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2013 Sander Botman.
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
 
require 'chef/knife'
 
class Chef
  class Knife
    class EnvironmentConstraints < Knife
 
      deps do
        require 'chef/environment'
        require 'chef/json_compat'
      end
 
      banner "knife environment constraints [ ENVIRONMENT ENVIRONMENT ]"
 
      def run
 
        environments = []
        unless @name_args.nil? || @name_args.empty?
          @name_args.each { |name| environments << name }
        else
          environments = Chef::Environment.list
        end
 
        cookbook_hash = {}
        cookbook_col = {}
 
        object_list = [ ui.color('', :bold) ]
 
        environments.each do |env,url|
          unless "#{env}" == "_default"
            envdata = Chef::Environment.load(env)
            cookbook_ver = envdata::cookbook_versions
            cookbook_col.merge!(cookbook_ver)
            cookbook_hash["#{env}"] = cookbook_ver
            object_list << ui.color("#{env}", :bold)
          end
        end
 
        if cookbook_col.nil? || cookbook_col.empty?
          ui.error "Cannot find any environment cookbook constraints"
          exit 1
        end
 
        columns = object_list.count
 
        cookbook_col.sort.each do |book,version|
          object_list << ui.color("#{book}", :bold)
 
          environments.each do |env,url|
            unless cookbook_hash["#{env}"].nil?
              if cookbook_hash["#{env}"].include?("#{book}")
                object_list << ui.color(cookbook_hash["#{env}"]["#{book}"])
              else
                object_list << ui.color("N/A", :red)
              end
            end
          end
 
        end
        puts ui.list(object_list, :uneven_columns_across, columns)
      end
 
    end
  end
end
