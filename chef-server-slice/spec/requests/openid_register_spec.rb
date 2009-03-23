require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/chefserverslice/openid_register" do
  
  before(:all) do
    mount_slice
  end

  describe "GET /" do
    before(:each) do
      @response = request("/chefserverslice/registrations")
    end

    it "should be successful" do
      @response.status.should be_successful
    end

    it "should have registered nodes list" do
      @response.should have_tag(:h3, :content=>"Registered OpenID Nodes List")
    end
  end

  after(:all) do
    dismount_slice
  end

end
