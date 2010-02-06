#
# Author:: Dreamcat4 (<dreamcat4@gmail.com>)
# Copyright:: Copyright (c) 2009 OpsCode, Inc.
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

require 'chef/provider/user'
require 'openssl'

class Chef
  class Provider
    class User
      class Dscl < Chef::Provider::User
        
        def dscl(*args)
          host = "."
          stdout_result = ""; stderr_result = ""; cmd = "dscl #{host} -#{args.join(' ')}"
          status = popen4(cmd) do |pid, stdin, stdout, stderr|
            stdout.each { |line| stdout_result << line }
            stderr.each { |line| stderr_result << line }
          end
          return [cmd, status, stdout_result, stderr_result]
        end

        def safe_dscl(*args)
          result = dscl(*args)
          return "" if ( args.first =~ /^delete/ ) && ( result[1].exitstatus != 0 )
          raise(Chef::Exceptions::User,"dscl error: #{result.inspect}") unless result[1].exitstatus == 0
          raise(Chef::Exceptions::User,"dscl error: #{result.inspect}") if result[2] =~ /No such key: /
          return result[2]
        end

        # This is handled in providers/group.rb by Etc.getgrnam()
        # def user_exists?(user)
        #   users = safe_dscl("list /Users")
        #   !! ( users =~ Regexp.new("\n#{user}\n") )
        # end

        # get a free UID greater than 200
        def get_free_uid(search_limit=1000)
          uid = nil; next_uid_guess = 200
          users_uids = safe_dscl("list /Users uid")
          while(next_uid_guess < search_limit + 200)
            if users_uids =~ Regexp.new("#{next_uid_guess}\n")
              next_uid_guess += 1
            else
              uid = next_uid_guess
              break
            end
          end
          return uid || raise("uid not found. Exhausted. Searched #{search_limit} times")
        end

        def uid_used?(uid)
          return false unless uid
          users_uids = safe_dscl("list /Users uid")
          !! ( users_uids =~ Regexp.new("#{uid}\n") )
        end

        def set_uid
          @new_resource.uid(get_free_uid) if [nil,""].include? @new_resource.uid
          raise(Chef::Exceptions::User,"uid is already in use") if uid_used?(@new_resource.uid)
          safe_dscl("create /Users/#{@new_resource.username} UniqueID #{@new_resource.uid}")
        end

        def modify_home
          return safe_dscl("delete /Users/#{@new_resource.username} NFSHomeDirectory") if (@new_resource.home.nil? || @new_resource.home.empty?)
          if @new_resource.supports[:manage_home]
            unless @new_resource.home =~ /^\//
              raise(Chef::Exceptions::User,"invalid path spec for User: '#{@new_resource.username}', home directory: '#{@new_resource.home}'") 
            end

            ch_eq_nh = ( @current_resource.home ==  @new_resource.home )
            cur_home_exists = ::File.exists?("#{@current_resource.home}")
            new_home_exists = ::File.exists?("#{@new_resource.home}")
            ditto = false
            move = false
            
            if ch_eq_nh
              if !new_home_exists
                ditto = true
              end
            else
              if !cur_home_exists
                if !new_home_exists
                  ditto = true
                end
              elsif cur_home_exists
                move = true
              end
            end

            if ditto
              skel = "/System/Library/User Template/English.lproj"
              raise(Chef::Exceptions::User,"can't find skel at: #{skel}") unless ::File.exists?(skel)
              run_command(:command => "ditto '#{skel}' '#{@new_resource.home}'")
              ::FileUtils.chown_R(@new_resource.username,@new_resource.gid.to_s,@new_resource.home)
            end

            if move
              src = @current_resource.home
              FileUtils.mkdir_p(@new_resource.home)
              files = ::Dir.glob("#{src}/*", ::File::FNM_DOTMATCH) - ["#{src}/.","#{src}/.."]
              ::FileUtils.mv(files,@new_resource.home, :force => true)
              ::FileUtils.rmdir(src)
              ::FileUtils.chown_R(@new_resource.username,@new_resource.gid.to_s,@new_resource.home)
            end
          end
          safe_dscl("create /Users/#{@new_resource.username} NFSHomeDirectory '#{@new_resource.home}'")
      end

        def osx_shadow_hash?(string)
          return !! ( string =~ /^[[:xdigit:]]{1240}$/ )
        end

        def osx_salted_sha1?(string)
          return !! ( string =~ /^[[:xdigit:]]{48}$/ )
        end

        def guid
          safe_dscl("read /Users/#{@new_resource.username} GeneratedUID").gsub(/GeneratedUID: /,"").gsub!(/\n/,"")
        end

        def shadow_hash_set?
          if safe_dscl("read /Users/#{@new_resource.username}") =~ /AuthenticationAuthority: /
            auth_auth = safe_dscl("read /Users/#{@new_resource.username} AuthenticationAuthority")
            return !! ( auth_auth =~ /ShadowHash/ )
          end
          return false
        end

        def modify_password
          if @new_resource.password
            shadow_hash = nil
            
            Chef::Log.debug("#{new_resource}: updating password")
            if osx_shadow_hash?(@new_resource.password)
              shadow_hash = @new_resource.password.upcase
            else
              salted_sha1 = nil
              if osx_salted_sha1?(@new_resource.password)
                salted_sha1 = @new_resource.password.upcase
              else
                hex_salt = ""; chars = ("0".."9").to_a + ("a".."f").to_a
                1.upto(8) { |i| hex_salt << chars[::Kernel.rand(chars.size-1)] }
                salt = [hex_salt].pack("H*")
                sha1 = ::OpenSSL::Digest::SHA1.hexdigest(salt+@new_resource.password)
                salted_sha1 = (hex_salt+sha1).upcase
              end
              shadow_hash = String.new("00000000"*155)
              shadow_hash[168] = salted_sha1
            end
            
            ::File.open("/var/db/shadow/hash/#{guid}",'w',0600) do |output|
              output.puts shadow_hash
            end
            
            unless shadow_hash_set?
              safe_dscl("append /Users/#{@new_resource.username} AuthenticationAuthority ';ShadowHash;'")
            end
          end
        end

        def load_current_resource
          super
          raise Chef::Exceptions::User, "Could not find binary /usr/bin/dscl for #{@new_resource}" unless ::File.exists?("/usr/bin/dscl")
        end

        def create_user
          manage_user(false)
        end
        
        def manage_user(manage = true)
          fields = []
          if manage
            [:username,:comment,:uid,:gid,:home,:shell,:password].each do |field|
              if @current_resource.send(field) != @new_resource.send(field)
                fields << field if @new_resource.send(field)
              end
            end
            if @new_resource.send(:supports)[:manage_home]
              fields << :home if @new_resource.send(:home)
            end
            fields << :shell if fields.include?(:password)
          else
            # create
            fields = [:username,:comment,:uid,:gid,:home,:shell,:password]
          end
          fields.uniq!
          fields.each do |field|
            case field
            when :username
              safe_dscl("create /Users/#{@new_resource.username}")              
              
            when :comment
              safe_dscl("create /Users/#{@new_resource.username} RealName '#{@new_resource.comment}'")

            when :uid
              set_uid
              
            when :gid
              safe_dscl("create /Users/#{@new_resource.username} PrimaryGroupID '#{@new_resource.gid}'")

            when :home
              modify_home

            when :shell
              if @new_resource.password || ::File.exists?("#{@new_resource.shell}")
                safe_dscl("create /Users/#{@new_resource.username} UserShell '#{@new_resource.shell}'")
              else
                safe_dscl("create /Users/#{@new_resource.username} UserShell '/usr/bin/false'")
              end

            when :password
              modify_password
            end
          end
        end
        
        def remove_user
          if @new_resource.supports[:manage_home]
            # remove home directory
            if safe_dscl("read /Users/#{@new_resource.username}") =~ /NFSHomeDirectory/
              nfs_home = safe_dscl("read /Users/#{@new_resource.username} NFSHomeDirectory")
              nfs_home.gsub!(/NFSHomeDirectory: /,"").gsub!(/\n$/,"")
              FileUtils.rm_rf(nfs_home)
            end
          end
          # remove the user from its groups
          groups = []
          Etc.group do |group|
            groups << group.name if group.mem.include?(@new_resource.username)
          end
          groups.each do |group_name|
            safe_dscl("delete /Groups/#{group_name} GroupMembership '#{@new_resource.username}'")
          end
          # remove user account
          safe_dscl("delete /Users/#{@new_resource.username}")
        end

        def locked?
          if safe_dscl("read /Users/#{@new_resource.username}") =~ /AuthenticationAuthority: /
            auth_auth = safe_dscl("read /Users/#{@new_resource.username} AuthenticationAuthority")
            return !! ( auth_auth =~ /DisabledUser/ )
          end
          return false
        end
        
        def check_lock
          return @locked = locked?
        end

        def lock_user
          safe_dscl("append /Users/#{@new_resource.username} AuthenticationAuthority ';DisabledUser;'")
        end
        
        def unlock_user
          auth_auth = safe_dscl("read /Users/#{@new_resource.username} AuthenticationAuthority")
          auth_auth.gsub!(/AuthenticationAuthority: /,"").gsub!(/DisabledUser/,"").gsub!(/[; ]*$/,"")
          safe_dscl("create /Users/#{@new_resource.username} AuthenticationAuthority '#{auth_auth}'")
        end
      end
    end
  end
end
