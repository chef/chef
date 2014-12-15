#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
require 'spec_helper'
require 'chef/resource/resource_notification'

describe Chef::Resource::Notification do
  before do
    @notification = Chef::Resource::Notification.new(:service_apache, :restart, :template_httpd_conf)
  end

  it "has a resource to be notified" do
    @notification.resource.should == :service_apache
  end

  it "has an action to take on the service" do
    @notification.action.should == :restart
  end

  it "has a notifying resource" do
    @notification.notifying_resource.should == :template_httpd_conf
  end

  it "is a duplicate of another notification with the same target resource and action" do
    other = Chef::Resource::Notification.new(:service_apache, :restart, :sync_web_app_code)
    @notification.duplicates?(other).should be_true
  end

  it "is not a duplicate of another notification if the actions differ" do
    other = Chef::Resource::Notification.new(:service_apache, :enable, :install_apache)
    @notification.duplicates?(other).should be_false
  end

  it "is not a duplicate of another notification if the target resources differ" do
    other = Chef::Resource::Notification.new(:service_sshd, :restart, :template_httpd_conf)
    @notification.duplicates?(other).should be_false
  end

  it "raises an ArgumentError if you try to check a non-ducktype object for duplication" do
    lambda {@notification.duplicates?(:not_a_notification)}.should raise_error(ArgumentError)
  end

  it "takes no action to resolve a resource reference that doesn't need to be resolved" do
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @notification.resource = @keyboard_cat
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @notification.notifying_resource = @long_cat
    @resource_collection = Chef::ResourceCollection.new
    # would raise an error since the resource is not in the collection
    @notification.resolve_resource_reference(@resource_collection)
    @notification.resource.should == @keyboard_cat
  end

  it "resolves a lazy reference to a resource" do
    @notification.resource = {:cat => "keyboard_cat"}
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @keyboard_cat
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @notification.notifying_resource = @long_cat
    @notification.resolve_resource_reference(@resource_collection)
    @notification.resource.should == @keyboard_cat
  end

  it "resolves a lazy reference to its notifying resource" do
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @notification.resource = @keyboard_cat
    @notification.notifying_resource = {:cat => "long_cat"}
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @long_cat
    @notification.resolve_resource_reference(@resource_collection)
    @notification.notifying_resource.should == @long_cat
  end

  it "resolves lazy references to both its resource and its notifying resource" do
    @notification.resource = {:cat => "keyboard_cat"}
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @keyboard_cat
    @notification.notifying_resource = {:cat => "long_cat"}
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @resource_collection << @long_cat
    @notification.resolve_resource_reference(@resource_collection)
    @notification.resource.should == @keyboard_cat
    @notification.notifying_resource.should == @long_cat
  end

  it "raises a RuntimeError if you try to reference multiple resources" do
    @notification.resource = {:cat => ["keyboard_cat", "cheez_cat"]}
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @cheez_cat = Chef::Resource::Cat.new("cheez_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @keyboard_cat
    @resource_collection << @cheez_cat
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @notification.notifying_resource = @long_cat
    lambda {@notification.resolve_resource_reference(@resource_collection)}.should raise_error(RuntimeError)
  end

  it "raises a RuntimeError if you try to reference multiple notifying resources" do
    @notification.notifying_resource = {:cat => ["long_cat", "cheez_cat"]}
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @cheez_cat = Chef::Resource::Cat.new("cheez_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @long_cat
    @resource_collection << @cheez_cat
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @notification.resource = @keyboard_cat
    lambda {@notification.resolve_resource_reference(@resource_collection)}.should raise_error(RuntimeError)
  end

  it "raises a RuntimeError if it can't find a resource in the resource collection when resolving a lazy reference" do
    @notification.resource = {:cat => "keyboard_cat"}
    @cheez_cat = Chef::Resource::Cat.new("cheez_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @cheez_cat
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @notification.notifying_resource = @long_cat
    lambda {@notification.resolve_resource_reference(@resource_collection)}.should raise_error(RuntimeError)
  end

  it "raises a RuntimeError if it can't find a notifying resource in the resource collection when resolving a lazy reference" do
    @notification.notifying_resource = {:cat => "long_cat"}
    @cheez_cat = Chef::Resource::Cat.new("cheez_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @cheez_cat
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @notification.resource = @keyboard_cat
    lambda {@notification.resolve_resource_reference(@resource_collection)}.should raise_error(RuntimeError)
  end

  it "raises an ArgumentError if improper syntax is used in the lazy reference to its resource" do
    @notification.resource = "cat => keyboard_cat"
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @keyboard_cat
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @notification.notifying_resource = @long_cat
    lambda {@notification.resolve_resource_reference(@resource_collection)}.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError if improper syntax is used in the lazy reference to its notifying resource" do
    @notification.notifying_resource = "cat => long_cat"
    @long_cat = Chef::Resource::Cat.new("long_cat")
    @resource_collection = Chef::ResourceCollection.new
    @resource_collection << @long_cat
    @keyboard_cat = Chef::Resource::Cat.new("keyboard_cat")
    @notification.resource = @keyboard_cat
    lambda {@notification.resolve_resource_reference(@resource_collection)}.should raise_error(ArgumentError)
  end

  # Create test to resolve lazy references to both notifying resource and dest. resource
  # Create tests to check proper error raising

end
