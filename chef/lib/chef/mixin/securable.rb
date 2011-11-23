#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

class Chef
  module Mixin
    module Securable

      def owner(arg=nil)
        set_or_return(
          :owner,
          arg,
          :regex => Chef::Config[:user_valid_regex]
        )
      end

      def group(arg=nil)
        set_or_return(
          :group,
          arg,
          :regex => Chef::Config[:group_valid_regex]
        )
      end

      def mode(arg=nil)
        set_or_return(
          :mode,
          arg,
          :callbacks => {
            "not in valid numeric range" => lambda { |m|
              if m.kind_of?(String)
                m =~ /^0/ || m="0#{m}"
              end

              # Windows does not support the sticky or setuid bits
              if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|windows/
                Integer(m)<=0777 && Integer(m)>=0
              else
                Integer(m)<=07777 && Integer(m)>=0
              end
            }
          }
        )
      end

      # TODO should this be separated into different files?
      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|windows/

        VALID_RIGHTS = [:read, :write, :full_control, :deny]

        # supports params like this:
        #
        #   rights :read, ["Administrators","Everyone"]
        #   rights :write, "Administrators"
        #
        # should also also allow multiple right declarations
        # in a single resource block as the data will be merged
        # into a single internal hash
        #
        # This method 'creates' rights attributes..this allows us to have
        # multiple instances of the attribute with separate runtime states.
        # See +Chef::Resource::RemoteDirectory+ for example usage (rights and files_rights)
        def self.rights_attribute(name)
          define_method(name) do |permission, *args|
            rights = nil
            unless permission == nil
              input = {:permission => permission.to_sym, :principal => args[0] }
              validations = {:permission => { :required => true, :equal_to => VALID_RIGHTS },
                              :principal => { :required => true, :kind_of => [String, Array] }}
              validate(input, validations)

              rights ||= (self.instance_variable_get("@#{name.to_s}".to_sym))
              rights ||= Hash.new

              # builds an internal hash like:
              #   {:write=>"Administrator", :read=>["Administrators", "Everyone"]}
              rights.merge!(input[:permission] => input[:principal])
            end
            set_or_return(
              name,
              rights,
              {}
            )
          end
        end
        # create a default 'rights' attribute
        rights_attribute(:rights)

        def inherits(arg=nil)
          set_or_return(
            :inherits,
            arg,
            :kind_of => [ TrueClass, FalseClass ]
          )
        end
      end
    end
  end
end
