#
# Cookbook:: end_to_end
# Recipe:: _java
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

node.default["java"]["install_flavor"] = "openjdk"
node.default["java"]["jdk_version"] = "11"

include_recipe "java::default"
