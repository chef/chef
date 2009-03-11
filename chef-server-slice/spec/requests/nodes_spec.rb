require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/chefserverslice/nodes/" do
  
  before(:all) do
    mount_slice
  end

  describe "GET /" do
    before(:each) do
      @response = request("/chefserverslice/nodes/")
    end

    it "should be successful" do
      @response.status.should be_successful
    end
  end
  
  after(:all) do
    dismount_slice
  end

end
