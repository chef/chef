=====================================================
Community Plugins
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/plugin_community.rst>`__

This page lists plugins for knife, Ohai, handlers, and the chef-client that are developed and maintained by the Chef community.

Knife
=====================================================
.. tag knife_summary

knife is a command-line tool that provides an interface between a local chef-repo and the Chef server. knife helps users to manage:

* Nodes
* Cookbooks and recipes
* Roles, Environments, and Data Bags
* Resources within various cloud environments
* The installation of the chef-client onto nodes
* Searching of indexed data on the Chef server

.. end_tag

knife plugins for cloud hosting platforms--- `knife azure <https://github.com/chef/knife-azure>`_, `knife bluebox <https://github.com/chef-boneyard/knife-bluebox>`_, `knife ec2 <https://github.com/chef/knife-ec2>`_, `knife eucalyptus <https://github.com/chef-boneyard/knife-eucalyptus>`_, `knife google <https://github.com/chef/knife-google>`_, `knife linode <https://github.com/chef/knife-linode>`_, `knife openstack <https://github.com/chef/knife-openstack>`_, and `knife rackspace <https://github.com/chef/knife-rackspace>`_, ---are built and maintained by Chef.

The following table lists knife plugins built by the Chef community.

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Plugin
     - Description
   * - `knife-audit <https://github.com/jbz/knife-audit>`_
     - Adds the ability to see how many (and which) nodes have a cookbook in its run-list.
   * - `knife-baremetalcloud <https://github.com/baremetalcloud/knife-baremetalcloud>`_
     - Adds the ability to manage compute nodes in baremetalcloud.
   * - `knife-batch <https://github.com/imeyer/knife-batch>`_
     - Adds the ability to execute commands like ``knife ssh``, but in groups of N with a sleep between execution iterations.
   * - `knife-block <https://github.com/greenandsecure/knife-block>`_
     - Adds the ability to create and manage multiple knife.rb files for working with many servers.
   * - `knife-brightbox <https://github.com/rubiojr/knife-brightbox>`_
     - Adds the ability to create, bootstrap, and manage instances in the brightbox cloud.
   * - `knife-bulk-change-environment <https://github.com/jonlives/knife-bulkchangeenvironment>`_
     - Adds the ability to move nodes from one environment to another.
   * - `knife-canon <https://github.com/lnxchk/Canon>`_
     - Adds the ability to compare command output across hosts.
   * - `knife-cfn <https://github.com/neillturner/knife-cfn>`_
     - Adds the ability to validate, create, describe, and delete stacks in AWS CloudFormation.
   * - `knife-cisco_asa <https://github.com/bflad/knife-cisco_asa>`_
     - Adds the ability to manage Cisco ASA devices.
   * - `knife-cleanup <https://github.com/mdxp/knife-cleanup>`_
     - Adds the ability to remove unused versions of cookbooks that are hosted on the Chef server. (Cookbook versions that are removed are backed-up prior to deletion.)
   * - `knife-cloudstack-fog <https://github.com/fifthecho/knife-cloudstack-fog>`_
     - Adds the ability to create, bootstrap, and manage instances in CloudStack using Fog, a Ruby gem for interacting with various cloud providers.
   * - `knife-cloudstack <https://github.com/CloudStack-extras/knife-cloudstack>`_
     - Adds the ability to create, bootstrap, and manage CloudStack instances.
   * - `knife-community <https://github.com/miketheman/knife-community>`_
     - Adds the ability to assist with deploying completed cookbooks to the community web site.
   * - `knife-crawl <https://github.com/jgoulah/knife-crawl>`_
     - Adds the ability to display the roles that are included recursively within a role and (optionally) all of the roles that include it.
   * - `knife-digital_ocean <https://github.com/rmoriz/knife-digital_ocean>`_
     - Adds the ability to create, bootstrap, and manage instances in DigitalOcean.
   * - `knife-ec2-amis-ubuntu <https://rubygems.org/gems/ubuntu_ami>`_
     - Adds the ability to retrieve a list of released Ubuntu Amazon Machine Images (AMI).
   * - `knife-elb <https://github.com/ranjib/knife-elb>`_
     - Adds the ability to add and remove instances from existing enterprise load balancers, enlist them, and then show them. (This does not add the ability to create or delete enterprise load balancers.)
   * - `knife-env-diff <https://github.com/jgoulah/knife-env-diff>`_
     - Adds the ability to diff the cookbook versions for two (or more) environments.
   * - `knife-esx <https://github.com/rubiojr/knife-esx>`_
     - Adds support for VMware.
   * - `knife-file <https://github.com/cparedes/knife-file>`_
     - Adds utilities that help manipulate files in a chef-repo.
   * - `knife-flip <https://github.com/jonlives/knife-flip>`_
     - Adds improvements to ``knife-set-environment`` with added functionality and failsafes.
   * - `knife-gandi <https://rubygems.org/gems/knife-gandi>`_
     - Adds the ability to create, bootstrap, and manage servers on the gandi.net hosting platform.
   * - `knife-gather <https://github.com/lnxchk/Gather>`_
     - Adds the ability to collate multi-line output from parallel ``knife ssh`` outputs into one section per host.
   * - `knife-github-cookbooks <https://github.com/websterclay/knife-github-cookbooks>`_
     - Adds the ability to create vendor branches automatically from any GitHub cookbook.
   * - `knife-glesys <https://github.com/smgt/knife-glesys>`_
     - Adds the ability to create, delete, list, and bootstrap servers on GleSYS.
   * - `knife-ipmi <https://github.com/Afterglow/knife-ipmi>`_
     - Adds simple power control of nodes using IPMI.
   * - `knife-kvm <https://github.com/rubiojr/knife-kvm>`_
     - Adds Linux support for KVM.
   * - `knife-lastrun <https://github.com/jgoulah/knife-lastrun>`_
     - Adds key metrics from the last chef-client run on a given node.
   * - `knife-ohno <https://github.com/lnxchk/Ohno>`_
     - Adds the ability to view nodes that haven't checked into the platform for N hours.
   * - `knife-oktawave <https://github.com/marek-siemdaj/knife-oktawave>`_
     - Adds the ability to manage Oktawave Cloud Instances.
   * - `knife-onehai <https://github.com/lnxchk/Knife-OneHai>`_
     - Adds the ability to get the last seen time of a single node.
   * - `knife-playground <https://github.com/rubiojr/knife-playground>`_
     - Adds miscellaneous tools for knife.
   * - `knife-plugins <https://github.com/danielsdeleo/knife-plugins>`_
     - Adds a set of plugins that help manage data bags.
   * - `knife-pocket <https://github.com/lnxchk/Pocket>`_
     - Adds the ability to save a knife search query for later use, such as when using ``knife ssh``.
   * - `knife-preflight <https://github.com/jonlives/knife-preflight>`_
     - Adds the ability to check which nodes and roles use a cookbook. This is helpful when making changes to a cookbook.
   * - `knife-profitbricks <https://github.com/profitbricks/knife-profitbricks>`_
     - Adds the ability to create, bootstrap, and manage instances in the ProfitBricks IaaS.
   * - `knife-rhn <https://github.com/bflad/knife-rhn>`_
     - Adds the ability to manage the Red Hat network.
   * - `knife-rightscale <https://github.com/caryp/knife-rightscale>`_
     - Adds the ability to provision servers on clouds managed by the RightScale platform.
   * - `knife-role_copy <https://github.com/benjaminws/knife_role_copy>`_
     - Adds the ability to get data from a role, and then set up a new role using that data (as long as the new role doesn't have the same name as an existing role).
   * - `knife-rvc <https://github.com/dougm/rvc-knife>`_
     - Integrates a subset of knife functionality with Ruby vSphere Console.
   * - `knife-santoku <https://github.com/knuckolls/knife-santoku>`_
     - Adds the ability to build processes around the chef-client.
   * - `knife-select <https://github.com/hpcloud/knife-select>`_
     - Adds the ability for selecting the chef server or organisation to interact with.
   * - `knife-server <https://github.com/fnichol/knife-server>`_
     - Adds the ability to manage a Chef server, including bootstrapping a Chef server on Amazon EC2 or a standalone server and backing up and/or restoring node, role, data bag, and environment data.
   * - `knife-set-environment <https://gist.github.com/961827>`_
     - Adds the ability to set a node environment.
   * - `knife-skeleton <https://github.com/Numergy/knife-skeleton>`_
     - Adds the ability to create skeleton integrating chefspec, rubocop, foodcritic, knife test and kitchen.
   * - `knife-softlayer <https://github.com/softlayer/knife-softlayer>`_
     - Adds the ability to launch and bootstrap instances in the IBM SoftLayer cloud.
   * - `knife-solo <https://rubygems.org/gems/knife-solo>`_
     - Adds support for bootstrapping and running chef-solo, search, and data bags.
   * - `knife-slapchop <https://github.com/kryptek/knife-slapchop>`_
     - Adds the ability create and tag clusters of Amazon EC2 nodes with a multi-threading bootstrap process.
   * - `knife-spork <https://github.com/jonlives/knife-spork>`_
     - Adds a simple environment workflow so that teams can more easily work together on the same cookbooks and environments.
   * - `knife-ssh_cheto <https://github.com/demonccc/chef-repo/tree/master/plugins/knife/ssh_cheto>`_
     - Adds extra features to be used with SSH.
   * - `knife-ucs <https://github.com/velankanisys/knife-ucs>`_
     - Adds the ability to provision, list, and manage Cisco UCS servers.
   * - `knife-voxel <https://github.com/warwickp/knife-voxel>`_
     - Adds the ability to provision instances in the Voxel cloud.
   * - `knife-whisk <https://github.com/Banno/knife-whisk>`_
     - Adds the ability to create new servers in a team environment.
   * - `knife-xapi <https://github.com/spheromak/knife-xapi>`_
     - Adds support for Citrix XenServer.

Ohai
=====================================================
.. tag ohai_summary

Ohai is a tool that is used to detect attributes on a node, and then provide these attributes to the chef-client at the start of every chef-client run. Ohai is required by the chef-client and must be present on a node. (Ohai is installed on a node as part of the chef-client install process.)

The types of attributes Ohai collects include (but are not limited to):

* Platform details
* Network usage
* Memory usage
* CPU data
* Kernel data
* Host names
* Fully qualified domain names
* Virtualization data
* Cloud provider metadata
* Other configuration details

Attributes that are collected by Ohai are automatic level attributes, in that these attributes are used by the chef-client to ensure that these attributes remain unchanged after the chef-client is done configuring the node.

.. end_tag

The following Ohai plugins are available from the open source community:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Plugin
     - Description
   * - `dell.rb <https://github.com/demonccc/chef-ohai-plugins/blob/master/dell.rb>`_
     - Adds some useful Dell server information to Ohai. For example: service tag, express service code, storage info, RAC info, and so on. To use this plugin, OMSA and SMBIOS applications need to be installed.
   * - `ipmi.rb <https://bitbucket.org/retr0h/ohai>`_
     - Adds a MAC address and an IP address to Ohai, where available.
   * - `kvm_extensions.rb <https://github.com/albertsj1/ohai-plugins/blob/master/kvm_extensions.rb>`_
     - Adds extensions for virtualization attributes to provide additional host and guest information for KVM.
   * - `ladvd.rb <https://github.com/demonccc/chef-ohai-plugins/blob/master/linux/ladvd.rb>`_
     - Adds ladvd information to Ohai, when it exists.
   * - `lxc_virtualization.rb <https://github.com/jespada/ohai-plugins/blob/master/lxc_virtualization.rb>`_
     - Adds extensions for virtualization attributes to provide host and guest information for Linux containers.
   * - `network_addr.rb <https://gist.github.com/1040543>`_
     - Adds extensions for network attributes with additional ``ipaddrtype_iface`` attributes to make it semantically easier to retrieve addresses.
   * - `network_ports.rb <https://github.com/agoddard/ohai-plugins/blob/master/plugins/network_ports.rb>`_
     - Adds extensions for network attributes so that Ohai can detect to which interfaces TCP and UDP ports are bound.
   * - `parse_host_plugin.rb <https://github.com/sbates/Chef-odds-n-ends/blob/master/ohai/parse_host_plugin.rb>`_
     - Adds the ability to parse a host name using three top-level attribute and five nested attributes.
   * - `r.rb <https://github.com/stevendanna/ohai-plugins/blob/master/plugins/r.rb>`_
     - Adds the ability to collect basic information about the R Project.
   * - `sysctl.rb <https://github.com/spheromak/cookbooks/blob/master/ohai/files/default/sysctl.rb>`_
     - Adds sysctl information to Ohai.
   * - `vserver.rb <https://github.com/albertsj1/ohai-plugins/blob/master/vserver.rb>`_
     - Adds extensions for virtualization attributes to allow a Linux virtual server host and guest information to be used by Ohai.
   * - `wtf.rb <https://github.com/cloudant/ohai_plugins/blob/master/wtf.rb>`_
     - Adds the irreverent wtfismyip.com service so that Ohai can determine a machine's external IPv4 address and geographical location.
   * - `xenserver.rb <https://github.com/spheromak/cookbooks/blob/master/ohai/files/default/xenserver.rb>`_
     - Adds extensions for virtualization attributes to load up Citrix XenServer host and guest information.
   * - `win32_software.rb <https://github.com/timops/ohai-plugins/blob/master/win32_software.rb>`_
     - Adds the ability for Ohai to use Windows Management Instrumentation (WMI) to discover useful information about software that is installed on any node that is running Microsoft Windows.
   * - `win32_svc.rb <https://github.com/timops/ohai-plugins/blob/master/win32_svc.rb>`_
     - Adds the ability for Ohai to query using Windows Management Instrumentation (WMI) to get information about all services that are registered on a node that is running Microsoft Windows.

Handlers
=====================================================
.. tag handler

Use a handler to identify situations that arise during a chef-client run, and then tell the chef-client how to handle these situations when they occur.

.. end_tag

.. tag handler_community_handlers

The following open source handlers are available from the Chef community:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Handler
     - Description
   * - `Airbrake <https://github.com/timops/ohai-plugins/blob/master/win32_svc.rb>`_
     - A handler that sends exceptions (only) to Airbrake, an application that collects data and aggregates it for review.
   * - `Asynchronous Resources <https://github.com/rottenbytes/chef/tree/master/async_handler>`_
     - A handler that asynchronously pushes exception and report handler data to a STOMP queue, from which data can be processed into data storage.
   * - `Campfire <https://github.com/ampledata/chef-handler-campfire>`_
     - A handler that collects exception and report handler data and reports it to Campfire, a web-based group chat tool.
   * - `Datadog <https://github.com/DataDog/chef-handler-datadog>`_
     - A handler that collects chef-client stats and sends them into a DATADOG newsfeed.
   * - `Flowdock <https://github.com/mmarschall/chef-handler-flowdock>`_
     - A handler that collects exception and report handler data and sends it to users via the Flowdock API..
   * - `Graphite <https://github.com/imeyer/chef-handler-graphite/wiki>`_
     - A handler that collects exception and report handler data and reports it to Graphite, a graphic rendering application.
   * - `Graylog2 GELF <https://github.com/jellybob/chef-gelf/>`_
     - A handler that provides exception and report handler status (including changes) to a Graylog2 server, so that the data can be viewed using Graylog Extended Log Format (GELF).
   * - `Growl <http://rubygems.org/gems/chef-handler-growl>`_
     - A handler that collects exception and report handler data and then sends it as a Growl notification.
   * - `HipChat <https://github.com/mojotech/hipchat/blob/master/lib/hipchat/chef.rb>`_
     - A handler that collects exception handler data and sends it to HipChat, a hosted private chat service for companies and teams.
   * - `IRC Snitch <https://rubygems.org/gems/chef-irc-snitch>`_
     - A handler that notifies administrators (via Internet Relay Chat (IRC)) when a chef-client run fails.
   * - `Journald <https://github.com/marktheunissen/chef-handler-journald>`_
     - A handler that logs an entry to the systemd journal with the chef-client run status, exception details, configurable priority, and custom details.
   * - `net/http <https://github.com/b1-systems/chef-handler-httpapi/>`_
     - A handler that reports the status of a Chef run to any API via net/HTTP.
   * - `Simple Email <https://rubygems.org/gems/chef-handler-mail>`_
     - A handler that collects exception and report handler data and then uses pony to send email reports that are based on Erubis templates.
   * - `SendGrid Mail Handler <https://github.com/sendgrid-ops/chef-sendgrid_mail_handler>`_
     - A chef handler that collects exception and report handler data and then uses SendGrid Ruby gem to send email reports that are based on Erubis templates.
   * - `SNS <http://onddo.github.io/chef-handler-sns/>`_
     - A handler that notifies exception and report handler data and sends it to a SNS topic.
   * - `Slack <https://github.com/rackspace-cookbooks/chef-slack_handler>`_
     - A handler to send chef-client run notifications to a Slack channel.
   * - `Splunk Storm <http://ampledata.org/splunk_storm_chef_handler.html>`_
     - A handler that supports exceptions and reports for Splunk Storm.
   * - `Syslog <https://github.com/jblaine/syslog_handler>`_
     - A handler that logs basic essential information, such as about the success or failure of a chef-client run.
   * - `Updated Resources <https://rubygems.org/gems/chef-handler-updated-resources>`_
     - A handler that provides a simple way to display resources that were updated during a chef-client run.
   * - `ZooKeeper <http://onddo.github.io/chef-handler-zookeeper/>`_
     - A Chef report handler to send Chef run notifications to ZooKeeper.

.. end_tag

chef-client
=====================================================
The following plugins are available for the chef-client:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Plugin
     - Description
   * - `chef-deploy <https://github.com/ezmobius/chef-deploy>`_
     - Adds a gem that contains resources and providers for deploying Ruby web applications from recipes.
   * - `chef-gelf <https://github.com/jellybob/chef-gelf>`_
     - Adds a handler that reports run status, including changes made to a Graylog2 server.
   * - `chef-handler-twitter <https://github.com/dje/chef-handler-twitter>`_
     - Adds a handler that tweets.
   * - `chef-handler-librato <https://github.com/bscott/chef-handler-librato>`_
     - Adds a handler that sends metrics to Librato's Metrics.
   * - `chef-hatch-repo <https://github.com/xdissent/chef-hatch-repo>`_
     - Adds a knife plugin and a Vagrant provisioner that can launch a self-managed Chef server in a virtual machine or Amazon EC2.
   * - `chef-irc-snitch <https://rubygems.org/gems/chef-irc-snitch>`_
     - Adds an exception handler for chef-client runs.
   * - `chef-jenkins <https://github.com/adamhjk/chef-jenkins>`_
     - Adds the ability to use Jenkins to drive continuous deployment and synchronization of environments from a git repository.
   * - `chef-rundeck <http://rubygems.org/gems/chef-rundeck>`_
     - Adds a resource endpoint for Rundeck.
   * - `chef-trac-hacks <http://trac-hacks.org/wiki/CloudPlugin>`_
     - Adds the ability to fill a coordination gap between Amazon Web Services (AWS) and the chef-client.
   * - `chef-vim <https://github.com/t9md/vim-chef>`_
     - Adds a plugin that makes cookbook navigation quick and easy.
   * - `chef-vpc-toolkit <https://github.com/rackerlabs/chef_vpc_toolkit>`_
     - Adds a set of Rake tasks that provide a framework that helps automate the creation and configuration of identical virtual server groups in the cloud.
   * - `jclouds-chef <https://github.com/jclouds/jclouds-chef>`_
     - Adds Java and Clojure components to the Chef server API REST API.
   * - `kitchenplan <https://github.com/kitchenplan/kitchenplan>`_
     - A utility for automating the installation and configuration of a workstation on macOS.
   * - `stove <https://github.com/sethvargo/stove>`_
     - A utility for releasing and managing cookbooks.
