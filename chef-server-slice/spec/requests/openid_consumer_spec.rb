require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/openid_consumer" do
  before(:each) do
    @response = request("/openid_consumer")
  end
end