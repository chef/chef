#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
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

require 'chef/win32/registry'
require 'spec_helper'

describe Chef::Resource::RegistryKey do

  before(:all) do
    events = Chef::EventDispatch::Dispatcher.new
    @node = Chef::Node.new
    ohai = Ohai::System.new
    ohai.all_plugins
    @node.consume_external_attrs(ohai.data,{})
    @run_context = Chef::RunContext.new(@node, {}, events)
    @resource = Chef::Resource::RegistryKey.new("HKCU\\Software\\Test", @run_context)
  end

  context "when action is create" do
    it "creates registry key, value tuple if the key is missing" do
      # resource.key_name("HKCU\\Software\\mytest")
      @resource.values([{:name=>'Apple', :type=>:multi_string, :data=>['Red', 'Sweet', 'Juicy']}])
      @resource.run_action(:create)
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test", Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg.each{|k,v|
          if k == 'Apple'
            @exists='true'
          else
            @exists='false' end}
      end
      @exists == 'true'
    end

    it "does not create the key if it already exists with same value, type and data" do
      @resource.values([{:name=>'Apple', :type=>:multi_string, :data=>['Red', 'Sweet', 'Juicy']}])
      @resource.run_action(:create)
      counter = 0
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test", Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg.each{|k,v|
          if k == 'Apple'
            counter = counter + 1
          end}
      end
      counter == 1
    end

   it "creates a value if it does not exist" do
     @resource.values([{:name=>'Mango', :type=>:string, :data=>'Yellow'}])
     @resource.run_action(:create)
     ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test", Win32::Registry::KEY_ALL_ACCESS) do |reg|
       reg.each{|k,v|
         if k == 'Mango'
           @existsMango='true'
         else
           @existsMango='false'
         end
         if k == 'Apple'
           @existsApple='true'
         else
           @existsApple='false'
         end
         }
       end
     @existsApple && @existaMango == 'true'
   end

    it "modifys the data and the type if the key and value already exist and type matches" do
      @resource.values([{:name=>'Apple', :type=>:multi_string, :data=>['Black', 'Magical', 'Rotten']}])
      @resource.run_action(:create)
      ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test", Win32::Registry::KEY_ALL_ACCESS) do |reg|
        reg.each{|k,v|
          if k == 'Apple'
            if v == ['Black', 'Magical', 'Rotten']
              @exists='true'
            end
          else
            @exists='false' end}
          end
       @exists == 'true'
     end

    it "gives an error if the key and value exist and the type does not match" do
    end

  #  it "creates subkey if parent exists" do
  #    @resource.key("HKCU\\Software\\Test\\OpscodeTest")
  #    @resource.values([{:name=>'OpscodeApple', :type=>:multi_string, :data=>['OpscodeOrange', 'OSweet']}])
  #    @resource.run_action(:create)
  #    ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test\\OpscodeTest", Win32::Registry::KEY_ALL_ACCESS) do |reg|
  #      reg.each{|k,v|
  #        if k == 'OpscodeApple'
  #          @exists='true'
  #        else
  #          @exists='false' end}
  #    end
  #    @exists == 'true'
  #  end

   # it "gives error if action create and parent does not exist and recursive is set to false" do
   # end

   # it "creates missing keys if action create and parent does not exist and recursive is set to true" do
   # end
   
   #it "Creates key with multiple value as specified" do
   #end

#    context "when the registry value exists and the action is :remove" do
#      it "removes the registry value if it exists" do
#        resource.key_name("HKCU\\Software\\Test")
#        resource.values({'Apple' => ['pink', 'amabt', 'wowww']})
#        resource.type(:multi_string)
#        resource.run_action(:remove)
#        ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test", Win32::Registry::KEY_ALL_ACCESS) do |reg|
#          reg.each{|k,v|
#            if k == 'Apple'
#              @exists='true'
#            else
#              @exists='false' 
#            end}
#        end
#      end
#    end
#
#      it "gives an error if the registry value does not exist" do
#        resource.values({'Banana' => ['Black', 'Magical', 'Rotten']})
#        resource.type(:multi_string)
#        resource.run_action(:create)
#        ::Win32::Registry::HKEY_CURRENT_USER.open("Software\\Test", Win32::Registry::KEY_ALL_ACCESS) do |reg|
#          reg.each{|k,v|
#            if k == 'Apple'
#              if v == ['Black', 'Magical', 'Rotten']
#                @exists='true'
#              end
#            else
#              @exists='false' end}
#            end
#         @exists == 'true'
#        end
#
#      it "plays around with the registry" do
#      ::Win32::Registry::HKEY_CURRENT_USER.open('Software\\Test') do |reg|
#        value = reg['Test']                               # read a value
#        puts "reg[Test]: #{reg[Test]}"
#        value = reg['Test', Win32::Registry::REG_SZ]      # read a value with type
#        puts "reg['Test', Win32::Registry::REG_SZ] #{reg['Test', Win32::Registry::REG_SZ]}"
#        type, value = reg.read('Test')                    # read a value
#        puts "reg.read('Test') #{reg.read('Test')}"
#        reg['Test'] = 'bar'                               # write a value
#        puts "reg['Test'] #{reg['Test']}"
#        reg['Test', Win32::Registry::REG_SZ] = 'bar'      # write a value with type
#        puts "reg['Test', Win32::Registry::REG_SZ] #{reg['Test', Win32::Registry::REG_SZ]}"
#        reg.write('Test', Win32::Registry::REG_SZ, 'bazzzz') # write a value
#      #  reg.each_value { |name, type, data| ... }        # Enumerate values
#      #  reg.each_key { |key, wtime| ... }                # Enumerate subkeys
#      #  reg.delete_value(name)                         # Delete a value
#      #  reg.delete_key(name)                           # Delete a subkey
#      #  reg.delete_key(name, true)                     # Delete a subkey recursively
#      end
#      end

   #   it "deletes sub keys if it exists else gives an error" do

   #   end

   #   it "deletes keys if they exist else gives an error" do

   #   end
   # end
  end
end
