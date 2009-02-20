require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbooks" do
  before(:each) do
    @response = request("/cookbooks")
  end
end