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

require 'tempfile'
require 'logger'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Log do
  it "should accept regular options to Logger.new via init" do
    tf = Tempfile.new("chef-test-log")
    tf.open
    lambda { Chef::Log.init(STDOUT) }.should_not raise_error
    lambda { Chef::Log.init(tf) }.should_not raise_error
  end
  
  it "should set the log level with :debug, :info, :warn, :error, or :fatal" do
    levels = {
      :debug => Logger::DEBUG,
      :info => Logger::INFO,
      :warn => Logger::WARN,
      :error => Logger::ERROR,
      :fatal => Logger::FATAL
    }
    levels.each do |symbol, constant|
      Chef::Log.level(symbol)
      Chef::Log.logger.level.should == constant
    end
  end
  
  it "should raise an ArgumentError if you try and set the level to something strange" do
    lambda { Chef::Log.level(:the_roots) }.should raise_error(ArgumentError)
  end
  
  it "should pass other method calls directly to logger" do
    Chef::Log.level(:debug)
    Chef::Log.should be_debug
    lambda { Chef::Log.debug("Gimme some sugar!") }.should_not raise_error
  end
  
  it "should default to STDOUT if init is called with no arguments" do
    logger_mock = mock(Logger, :null_object => true)
    Logger.stub!(:new).and_return(logger_mock)
    Logger.should_receive(:new).with(STDOUT).and_return(logger_mock)
    Chef::Log.init
  end
  
end