require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbook_attributes" do
  before(:each) do
    @response = request("/cookbook_attributes")
  end
end