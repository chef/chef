= chef

* http://oss.hjksolutions.com/chef

== DESCRIPTION:

Chef is a configuration management tool inspired by Puppet. 

I'm in ur netwerk, cookin up yer servers. :)

== FEATURES/PROBLEMS:


== SYNOPSIS:


== REQUIREMENTS:

RubyGems:

* stomp
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

		./bin/chef-indexer -l debug -c ./config/chef-server.rb

  * Start chef-server on port 4000 with:

    ./bin/chef-server

  * Start chef-server on port 4001 with:

    ./bin/chef-server -p 4001

  * Test run chef with:

    sudo ./bin/chef-client -l debug -c ./examples/config/chef-solo.rb

== LICENSE:

Chef - A configuration management system

Copyright 2008 HJK Solutions

This program and entire repository is free software; you can
redistribute it and/or modify it under the terms of the GNU 
General Public License as published by the Free Software 
Foundation; either version 2 of the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
