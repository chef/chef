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

require 'time'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Log::Formatter do
  before(:each) do
    @formatter = Chef::Log::Formatter.new
  end
  
  it "should print raw strings with msg2str(string)" do
    @formatter.msg2str("nuthin new").should == "nuthin new"
  end
  
  it "should format exceptions properly with msg2str(e)" do
    e = IOError.new("legendary roots crew")
    @formatter.msg2str(e).should == "legendary roots crew (IOError)\n"
  end
  
  it "should format random objects via inspect with msg2str(Object)" do
    @formatter.msg2str([ "black thought", "?uestlove" ]).should == '["black thought", "?uestlove"]'
  end
  
  it "should return a formatted string with call" do
    time = Time.new
    @formatter.call("monkey", Time.new, "test", "mos def").should == "[#{time.rfc2822}] monkey: mos def\n"
  end
  
end