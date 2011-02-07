#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require 'pp'
require 'stringio'
require 'rubygems'
require 'bunny'
$:.unshift(File.expand_path('../../lib/', __FILE__))
require 'chef/expander'

include Chef

OPSCODE_EXPANDER_MQ_CONFIG = {:user => "guest", :pass => "guest", :vhost => '/chef-expander-test'}

HOW_TO_SETUP=<<-ERROR

****************************** FAIL *******************************************
* Running these tests requires a running instance of rabbitmq
* You also must configure a vhost "/chef-expander-test"
* and a user "guest" with password "guest" with full rights
* to that vhost
-------------------------------------------------------------------------------
> rabbitmq-server
> rabbitmqctl add_vhost /chef-expander-test
> rabbitmqctl set_permissions -p /chef-expander-test guest '.*' '.*' '.*'
> rabbitmqctl list_user_permissions guest
****************************** FAIL *******************************************

ERROR

def debug_exception_to_stderr(e)
  if ENV['DEBUG'] == "true"
    STDERR.puts("#{e.class.name}: #{e.message}")
    STDERR.puts("#{e.backtrace.join("\n")}")
  end
end

begin
  b = Bunny.new(OPSCODE_EXPANDER_MQ_CONFIG)
  b.start
  b.stop
rescue Bunny::ProtocolError, Bunny::ServerDownError, Bunny::ConnectionError => e
  STDERR.puts(HOW_TO_SETUP)
  debug_exception_to_stderr(e)
  exit(1)
rescue Exception => e
  STDERR.puts(<<-EXPLAIN)
An unknown error occurred verifying prerequisites for unit tests.
This is most commonly caused by incorrect permissions settings in rabbitmq.

Run with DEBUG=true to see the error.

EXPLAIN
  STDERR.puts(HOW_TO_SETUP)
  debug_exception_to_stderr(e)
  exit(2)
end

FIXTURE_PATH = File.expand_path('../fixtures', __FILE__)
