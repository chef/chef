require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/openid_register" do
  before(:each) do
    @response = request("/openid_register")
  end
end