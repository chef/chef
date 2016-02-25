require "chef/config"
require "chef/mixin/fips"
require "spec_helper"

shared_context "allow md5" do
  include Chef::Mixin::FIPS
  before do
    allow_md5 if fips?
  end

  after do
    disallow_md5 if fips?
  end

end
