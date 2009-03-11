require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/exceptions" do
  before(:each) do
    @response = request("/exceptions")
  end
end