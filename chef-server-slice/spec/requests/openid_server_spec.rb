require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/openid_server" do
  before(:each) do
    @response = request("/openid_server")
  end
end