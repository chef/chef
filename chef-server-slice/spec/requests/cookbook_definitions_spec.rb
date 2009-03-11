require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbook_definitions" do
  before(:each) do
    @response = request("/cookbook_definitions")
  end
end