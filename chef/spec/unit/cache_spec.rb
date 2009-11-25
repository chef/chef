#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Cache do
  before(:each) do
    Chef::Config[:cache_type] = "Memory"
    Chef::Config[:cache_options] = { } 
    @cache = Chef::Cache.new
  end

  describe "initialize" do
    it "should build a Chef::Cache object" do
      @cache.should be_a_kind_of(Chef::Cache)
    end

    it "should set up a Moneta Cache adaptor" do
      @cache.moneta.should be_a_kind_of(Moneta::Memory)
    end

    it "should raise an exception if it cannot load the moneta adaptor" do
      lambda {
        c = Chef::Cache.new('WTF')
      }.should raise_error(LoadError)
    end
  end

  describe "method_missing" do
    it "should proxy calls to the moneta object" do
      @cache[:you] = "a monkey"
      @cache[:you].should == "a monkey"
    end
  end

end
