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

      alias :user :owner

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
              if Chef::Platform.windows?
                Integer(m)<=0777 && Integer(m)>=0
              else
                Integer(m)<=07777 && Integer(m)>=0
              end
            },
          }
        )
      end

      # TODO should this be separated into different files?
      if RUBY_PLATFORM =~ /mswin|mingw|windows/

        # supports params like this:
        #
        #   rights :read, ["Administrators","Everyone"]
        #   rights :deny, "Pinky"
        #   rights :full_control, "Users", :applies_to_children => true
        #   rights :write, "John Keiser", :applies_to_children => :containers_only, :applies_to_self => false, :one_level_deep => true
        #
        # should also also allow multiple right declarations
        # in a single resource block as the data will be merged
        # into a single internal hash
        #
        # This method 'creates' rights attributes..this allows us to have
        # multiple instances of the attribute with separate runtime states.
        # See +Chef::Resource::RemoteDirectory+ for example usage (rights and files_rights)
        def self.rights_attribute(name)
          define_method(name) do |*args|
            # Ruby 1.8 compat: default the arguments
            permissions = args.length >= 1 ? args[0] : nil
            principals = args.length >= 2 ? args[1] : nil
            args_hash = args.length >= 3 ? args[2] : nil
            raise ArgumentError.new("wrong number of arguments (#{args.length} for 3)") if args.length >= 4

            rights = self.instance_variable_get("@#{name.to_s}".to_sym)
            unless permissions == nil
              input = {
                :permissions => permissions,
                :principals => principals
              }
              input.merge!(args_hash) if args_hash != nil

              validations = {:permissions => { :required => true },
                             :principals => { :required => true, :kind_of => [String, Array] },
                             :applies_to_children => { :equal_to => [ true, false, :containers_only, :objects_only ]},
                             :applies_to_self => { :kind_of => [ TrueClass, FalseClass ] },
                             :one_level_deep => { :kind_of => [ TrueClass, FalseClass ] }
                            }
              validate(input, validations)

              [ permissions ].flatten.each do |permission|
                if permission.is_a?(Integer)
                  if permission < 0 || permission > 1<<32
                    raise ArgumentError, "permissions flags must be positive and <= 32 bits (#{permission})"
                  end
                elsif !([:full_control, :modify, :read_execute, :read, :write].include?(permission.to_sym))
                  raise ArgumentError, "permissions parameter must be :full_control, :modify, :read_execute, :read, :write or an integer representing Windows permission flags"
                end
              end

              [ principals ].flatten.each do |principal|
                if !principal.is_a?(String)
                  raise ArgumentError, "principals parameter must be a string or array of strings representing usernames"
                end
              end

              if input[:applies_to_children] == false
                if input[:applies_to_self] == false
                  raise ArgumentError, "'rights' attribute must specify either :applies_to_children or :applies_to_self."
                end
                if input[:one_level_deep] == true
                  raise ArgumentError, "'rights' attribute specified :one_level_deep without specifying :applies_to_children."
                end
              end
              rights ||= []
              rights << input
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
        rights_attribute(:deny_rights)

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
