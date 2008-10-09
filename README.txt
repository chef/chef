= chef

* http://oss.hjksolutions.com/chef

== DESCRIPTION:

Chef is a configuration management tool.

I'm in ur netwerk, cookin up yer servers. :)

== FEATURES/PROBLEMS:


== SYNOPSIS:


== REQUIREMENTS:

RubyGems:

* stomp
* stompserver
* ultraviolet
* facter
* ferret
* merb-core
* haml
* ruby-openid
* json

External Servers:

* stompserver (for easy stomp mq testing)
* CouchDB

== INSTALL:

Install all of the above.  To fire up a develpment environment, do the following:

  * Start CouchDB with 'couchdb'
  * Start stompserver with 'stompserver' 
  * Start chef-indexer with:

		chef-indexer -l debug 

  * Start chef-server:

    chef-server -N -c 2

  * Test run chef with:

    chef-client -l debug

== LICENSE:

Chef - A configuration management system

Author:: Adam Jacob (<adam@hjksolutions.com>)
Copyright:: Copyright (c) 2008 HJK Solutions, LLC
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

