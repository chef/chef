#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

# == net-ssh-multi gem patch for concurrency
# net-ssh-multi gem has 2 bugs associated with the use of
# :concurrent_connections option.
# 1-) There is a race condition while fetching the next_session when
# :concurrent_connections are set. @open_connections is being
# incremented by the connection thread and sometimes
# realize_pending_connections!() method can create more than required
# connection threads before the @open_connections is set by the
# previously created threads.
# 2-) When :concurrent_connections is set, server classes are setup
# with PendingConnection objects that always return true to busy?
# calls. If a connection fails when :concurrent_connections is set,
# server ends up returning true to all busy? calls since the session
# object is not replaced. Due to this, main event loop (process()
# function) never gets terminated.
#
# See: https://github.com/net-ssh/net-ssh-multi/pull/4

require 'net/ssh/multi/version'

if Net::SSH::Multi::Version::STRING == "1.1.0" || Net::SSH::Multi::Version::STRING == "1.2.0"

  require 'net/ssh/multi'

  module Net
    module SSH
      module Multi
        class Server

          # Make sure that server returns false if the ssh connection
          # has failed.
          def busy?(include_invisible=false)
            !failed? && session && session.busy?(include_invisible)
          end

        end

        class Session
          def next_session(server, force=false) #:nodoc:
            # don't retry a failed attempt
            return nil if server.failed?

            @session_mutex.synchronize do
              if !force && concurrent_connections && concurrent_connections <= open_connections
                connection = PendingConnection.new(server)
                @pending_sessions << connection
                return connection
              end

              # ===== PATCH START
              # Only increment the open_connections count if the connection
              # is not being forced. Incase of a force, it will already be
              # incremented.
              if !force
                @open_connections += 1
              end
              # ===== PATCH END
            end

            begin
              server.new_session

              # I don't understand why this should be necessary--StandardError is a
              # subclass of Exception, after all--but without explicitly rescuing
              # StandardError, things like Errno::* and SocketError don't get caught
              # here!
            rescue Exception, StandardError => e
              server.fail!
              @session_mutex.synchronize { @open_connections -= 1 }

              case on_error
              when :ignore then
                # do nothing
              when :warn then
                warn("error connecting to #{server}: #{e.class} (#{e.message})")
              when Proc then
                go = catch(:go) { on_error.call(server); nil }
                case go
                when nil, :ignore then # nothing
                when :retry then retry
                when :raise then raise
                else warn "unknown 'go' command: #{go.inspect}"
                end
              else
                raise
              end

              return nil
            end
          end

          def realize_pending_connections! #:nodoc:
            return unless concurrent_connections

            server_list.each do |server|
              server.close if !server.busy?(true)
              server.update_session!
            end

            @connect_threads.delete_if { |t| !t.alive? }

            count = concurrent_connections ? (concurrent_connections - open_connections) : @pending_sessions.length
            count.times do
              session = @pending_sessions.pop or break
              # ===== PATCH START
              # Increment the open_connections count here to prevent
              # creation of connection thread again before that is
              # incremented by the thread.
              @session_mutex.synchronize { @open_connections += 1 }
              # ===== PATCH END
              @connect_threads << Thread.new do
                session.replace_with(next_session(session.server, true))
              end
            end
          end

        end
      end
    end
  end

end
