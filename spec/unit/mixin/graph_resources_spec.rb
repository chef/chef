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

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe Marionette::Mixin::GraphResources do
  it "should find a resource by symbol and name, or array of names" do
    @recipe = Marionette::Recipe.new("one", "two", "three")
    %w{monkey dog cat}.each do |name|
      @recipe.zen_master name do
        peace = true
      end
    end
    doggie = @recipe.resources(:zen_master => "dog")
    doggie.name.should eql("dog") # clever, I know
    multi_zen = [ "dog", "monkey" ]
    zen_array = @recipe.resources(:zen_master => multi_zen)
    zen_array.length.should eql(2)
    zen_array.each_index do |i|
      zen_array[i].name.should eql(multi_zen[i])
      zen_array[i].resource_name.should eql(:zen_master)
    end
  end
end