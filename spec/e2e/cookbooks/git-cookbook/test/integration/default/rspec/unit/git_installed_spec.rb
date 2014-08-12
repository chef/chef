
require 'spec_helper'

require 'chef/mixin/shell_out'

describe "git-cookbook cookbook" do
  include Chef::Mixin::ShellOut

  it "should install git" do
    so = shell_out('which git')
    so.exitstatus.should == 0
  end
end
