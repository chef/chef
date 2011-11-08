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

# CHEF EXPANDER CONFIGURATION ######
# A Sample config file for spec tests #
#######################################

## The Actual Config Settings for Chef Expander ##
# Solr
solr_url        "http://localhost:8983/solr"

## Parameters for connecting to RabbitMQ ##
# Defaults:
#amqp_host   'localhost'
#amqp_port   '5672'
#amqp_user   'guest'
amqp_pass   'config-file' # should override the defaults
amqp_vhost  '/config-file'

## Cluster Config, should be overridden by command line ##
node_count 42
## Extraneous Crap (should be ignored and not raise an error) ##

solr_ram_use "1024T"
another_setting "#{solr_ram_use} is an alot"