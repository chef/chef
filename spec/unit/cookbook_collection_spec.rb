#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

# require File.join(File.dirname(__FILE__), "..", "spec_helper")
# 
# describe Chef::CookbookCollection do
#   before(:each) do
#     config = Chef::Config.new
#     config.cookbook_path = [ 
#       File.join(File.dirname(__FILE__), "..", "data", "cookbooks") 
#       File.join(File.dirname(__FILE__), "..", "data", "kitchen-cookbooks") 
#     ]
#     @cc = Chef::CookbookCollection.new(config)
#   end
#   
#   it "should be a Chef::CookbookCollection object" do
#     @cookbooks.should be_kind_of(Chef::CookbookCollection)
#   end
#   
#   it "should return a list of available cookbooks as []" do
#     @cookbooks[:openldap].should
#   end
#   
#   it "should allow you to iterate over cookbooks with each" do
#   end
# 
#   it "should auto-load a cookbook via [] if it isn't loaded already" do
#   end
#   
#   it "should find all the cookbooks in the cookbook path" do
#   end
#   
#   it "should allow you to override an attribute file via cookbook_path" do
#   end
#   
#   it "should allow you to override a definition file via cookbook_path" do
#   end
#   
#   it "should allow you to override a recipe file via cookbook_path" do
#   end
#   
#   it "should allow you to declare a cookbook as 'final', and not look for any other" do
#   end
#   
#   it "should allwo you to have an 'ignore' file, which skips loading files in later cookbooks" do
#   end
#   
# end