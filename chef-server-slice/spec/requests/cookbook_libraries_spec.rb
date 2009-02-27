require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbook_libraries" do
  before(:each) do
    @response = request("/cookbook_libraries")
  end
end