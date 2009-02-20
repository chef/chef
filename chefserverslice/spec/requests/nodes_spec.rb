require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/nodes" do
  before(:each) do
    @response = request("/nodes")
  end
end