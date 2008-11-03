#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

class TinyTemplateClass; include Chef::Mixin::Template; end

describe Chef::Mixin::Template, "render_template" do
  
  before(:each) do
    @template = "abcnews"
    @context = { :fine => "dear" }
    @eruby = mock(:erubis, { :evaluate => "elvis costello" })
    Erubis::Eruby.stub!(:new).and_return(@eruby)
    @tempfile = mock(:tempfile, { :print => true, :close => true })
    Tempfile.stub!(:new).and_return(@tempfile)
    @tiny_template = TinyTemplateClass.new
  end
  
  it "should create a new Erubis object from the template" do
    Erubis::Eruby.should_receive(:new).with("abcnews").and_return(@eruby)
    @tiny_template.render_template(@template, @context)
  end
  
  it "should evaluate the template with the provided context" do
    @eruby.should_receive(:evaluate).with(@context).and_return(true)
    @tiny_template.render_template(@template, @context)
  end
  
  it "should create a tempfile for the resulting file" do
    Tempfile.should_receive(:new).and_return(@tempfile)
    @tiny_template.render_template(@template, @context)
  end
  
  it "should print the contents of the resulting template to the tempfile" do
    @tempfile.should_receive(:print).with("elvis costello").and_return(true)
    @tiny_template.render_template(@template, @context)
  end
  
  it "should close the tempfile" do
    @tempfile.should_receive(:close).and_return(true)
    @tiny_template.render_template(@template, @context)
  end
end

