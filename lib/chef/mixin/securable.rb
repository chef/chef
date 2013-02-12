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


      #==WindowsMacros
      # Defines methods for adding attributes to a chef resource to describe
      # Windows file security metadata.
      #
      # This module is meant to be used to extend a class (instead of
      # `include`-ing). A class is automatically extended with this module when
      # it includes WindowsSecurableAttributes.
      # --
      # TODO should this be separated into different files?
      module WindowsMacros
        # === rights_attribute
        # "meta-method" for dynamically creating rights attributes on resources.
        #
        # Multiple rights attributes can be declared. This enables resources to
        # have multiple rights attributes with separate runtime states.
        #
        # For example, +Chef::Resource::RemoteDirectory+ supports different
        # rights on the directories and files by declaring separate rights
        # attributes for each (rights and files_rights).
        #
        # ==== User Level API
        # Given a resource that calls
        #
        #   rights_attribute(:rights)
        #
        # Then the resource DSL could be used like this:
        #
        #   rights :read, ["Administrators","Everyone"]
        #   rights :deny, "Pinky"
        #   rights :full_control, "Users", :applies_to_children => true
        #   rights :write, "John Keiser", :applies_to_children => :containers_only, :applies_to_self => false, :one_level_deep => true
        #
        # ==== Internal Data Structure
        # rights attributes support multiple right declarations
        # in a single resource block--the data will be merged
        # into a single internal hash.
        #
        # The internal representation is a hash with the following keys:
        #
        # * `:permissions`: Integer of Windows permissions flags, 1..2^32
        # or one of `[:full_control, :modify, :read_execute, :read, :write]`
        # * `:principals`:  String or Array of Strings represnting usernames on
        # the system.
        # * `:applies_to_children` (optional): Boolean
        # * `:applies_to_self` (optional): Boolean
        # * `:one_level_deep` (optional): Boolean
        #
        def rights_attribute(name)

          # equivalent to something like:
          # def rights(permissions=nil, principals=nil, args_hash=nil)
          define_method(name) do |*args|
            # Ruby 1.8 compat: default the arguments
            permissions = args.length >= 1 ? args[0] : nil
            principals = args.length >= 2 ? args[1] : nil
            args_hash = args.length >= 3 ? args[2] : nil
            raise ArgumentError.new("wrong number of arguments (#{args.length} for 3)") if args.length >= 4

            rights = self.instance_variable_get("@#{name.to_s}".to_sym)
            unless permissions.nil?
              input = {
                :permissions => permissions,
                :principals => principals
              }
              input.merge!(args_hash) unless args_hash.nil?

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
      end

      #==WindowsSecurableAttributes
      # Defines #inherits to describe Windows file security ACLs on the
      # including class
      module WindowsSecurableAttributes


        def inherits(arg=nil)
          set_or_return(
            :inherits,
            arg,
            :kind_of => [ TrueClass, FalseClass ]
          )
        end
      end

      if RUBY_PLATFORM =~ /mswin|mingw|windows/
        include WindowsSecurableAttributes
      end

      # Callback that fires when included; will extend the including class
      # with WindowsMacros and define #rights and #deny_rights on it.
      def self.included(including_class)
        if RUBY_PLATFORM =~ /mswin|mingw|windows/
          including_class.extend(WindowsMacros)
          # create a default 'rights' attribute
          including_class.rights_attribute(:rights)
          including_class.rights_attribute(:deny_rights)
        end
      end

    end
  end
end
