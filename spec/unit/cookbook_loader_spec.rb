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

require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Chef::CookbookLoader do
  before(:each) do
    config = Chef::Config.new
    config.cookbook_path [ 
      File.join(File.dirname(__FILE__), "..", "data", "cookbooks"),
      File.join(File.dirname(__FILE__), "..", "data", "kitchen") 
    ]
    @cl = Chef::CookbookLoader.new(config)
  end
  
  it "should be a Chef::CookbookLoader object" do
    @cl.should be_kind_of(Chef::CookbookLoader)
  end
  
  it "should return cookbook objects with []" do
    @cl[:openldap].should be_a_kind_of(Chef::Cookbook)
  end
  
  it "should allow you to look up available cookbooks with [] and a symbol" do
    @cl[:openldap].name.should eql(:openldap)
  end
  
  it "should allow you to look up available cookbooks with [] and a string" do
    @cl["openldap"].name.should eql(:openldap)
  end
  
  it "should allow you to iterate over cookbooks with each" do
    seen = Hash.new
    @cl.each do |cb|
      seen[cb.name] = true
    end
    seen.should have_key(:openldap)
    seen.should have_key(:apache2)
  end
  
  it "should find all the cookbooks in the cookbook path" do
    @cl.config.cookbook_path << File.join(File.dirname(__FILE__), "..", "data", "hidden-cookbooks") 
    @cl.load_cookbooks
    @cl.detect { |cb| cb.name == :openldap }.should_not eql(nil)
    @cl.detect { |cb| cb.name == :apache2 }.should_not eql(nil)
  end
  
  it "should allow you to override an attribute file via cookbook_path" do
    @cl[:openldap].attribute_files.detect { |f| 
      f =~ /cookbooks\/openldap\/attributes\/default.rb/
    }.should_not eql(nil)
    @cl[:openldap].attribute_files.detect { |f| 
      f =~ /kitchen\/openldap\/attributes\/default.rb/
    }.should eql(nil)
  end
  
  it "should load different attribute files from deeper paths" do
    @cl[:openldap].attribute_files.detect { |f| 
      f =~ /kitchen\/openldap\/attributes\/robinson.rb/
    }.should_not eql(nil)
  end
  
  it "should allow you to override a definition file via cookbook_path" do
    @cl[:openldap].definition_files.detect { |f| 
      f =~ /cookbooks\/openldap\/definitions\/client.rb/
    }.should_not eql(nil)
    @cl[:openldap].definition_files.detect { |f| 
      f =~ /kitchen\/openldap\/definitions\/client.rb/
    }.should eql(nil)
  end
  
  it "should load definition files from deeper paths" do
    @cl[:openldap].definition_files.detect { |f| 
      f =~ /kitchen\/openldap\/definitions\/drewbarrymore.rb/
    }.should_not eql(nil)
  end
  
  it "should allow you to override a recipe file via cookbook_path" do
    @cl[:openldap].recipe_files.detect { |f| 
      f =~ /cookbooks\/openldap\/recipes\/gigantor.rb/
    }.should_not eql(nil)
    @cl[:openldap].recipe_files.detect { |f| 
      f =~ /kitchen\/openldap\/recipes\/gigantor.rb/
    }.should eql(nil)
  end
  
  it "should load recipe files from deeper paths" do
    @cl[:openldap].recipe_files.detect { |f| 
      f =~ /kitchen\/openldap\/recipes\/woot.rb/
    }.should_not eql(nil)
  end
  
  it "should allow you to have an 'ignore' file, which skips loading files in later cookbooks" do
    @cl[:openldap].recipe_files.detect { |f| 
      f =~ /kitchen\/openldap\/recipes\/ignoreme.rb/
    }.should eql(nil)
  end
  
end