require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe OpenidRegister, "index action" do  
  it "should get a list of all registered nodes" do
    Chef::FileStore.should_receive(:list).with("openid_node").and_return(["one"])
    dispatch_to(OpenidRegister, :index) do |c|
      c.stub!(:display)
    end
  end
end

describe OpenidRegister, "show action" do  
  it "should raise a 404 if the nodes registration is not found" do
    Chef::FileStore.should_receive(:load).with("openid_node", "foo").and_raise(RuntimeError)
    lambda { 
      dispatch_to(OpenidRegister, :show, { :id => "foo" }) 
    }.should raise_error(Merb::ControllerExceptions::NotFound)
  end
  
  it "should call display on the node registration" do
    Chef::FileStore.stub!(:load).and_return(true)
    dispatch_to(OpenidRegister, :show, { :id => "foo" }) do |c|
      c.should_receive(:display).with(true)
    end
  end
end

describe OpenidRegister, "create action" do
  def do_create
    dispatch_to(OpenidRegister, :create, { :id => "foo", :password => "beck" }) do |c|
      c.stub!(:display)
    end
  end
  
  it "should require an id to register" do
    lambda {
      dispatch_to(OpenidRegister, :create, { :password => "beck" }) 
    }.should raise_error(Merb::ControllerExceptions::BadRequest)
  end
  
  it "should require a password to register" do
    lambda { 
      dispatch_to(OpenidRegister, :create, { :id => "foo" }) 
    }.should raise_error(Merb::ControllerExceptions::BadRequest)
  end
  
  it "should return 400 if a node is already registered" do
    Chef::FileStore.should_receive(:has_key?).with("openid_node", "foo").and_return(true)
    lambda { 
      dispatch_to(OpenidRegister, :create, { :id => "foo", :password => "beck" }) 
    }.should raise_error(Merb::ControllerExceptions::BadRequest)
  end
  
  it "should store the registered node in the file store" do
    Chef::FileStore.stub!(:has_key?).and_return(false)
    Chef::FileStore.should_receive(:store).and_return(true)
    do_create
  end
end

describe OpenidRegister, "update action" do
  it "should raise a 400 error" do
    lambda { 
      dispatch_to(OpenidRegister, :update)
    }
  end
end

describe OpenidRegister, "destroy action" do
  def do_destroy
    dispatch_to(OpenidRegister, :destroy, { :id => "foo" }) do |c|
      c.stub!(:display)
    end
  end
  
  it "should return 400 if it cannot find the registration" do
    Chef::FileStore.should_receive(:has_key?).with("openid_node", "foo").and_return(false)
    lambda { 
      do_destroy
    }.should raise_error(Merb::ControllerExceptions::BadRequest)
  end
  
  it "should delete the registration from the store" do
    Chef::FileStore.stub!(:has_key?).and_return(true)
    Chef::FileStore.should_receive(:delete).with("openid_node", "foo").and_return(true)
    do_destroy
  end
end