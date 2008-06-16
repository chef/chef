require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe OpenidConsumer, "check_valid_openid_provider method" do  
  it "should confirm the openid provider if the openid_providers config is nil" do
    Chef::Config[:openid_providers] = nil   
    c = OpenidConsumer.new(true)
    c.send(:check_valid_openid_provider, "monkeyid").should eql(true)
  end
  
  it "should return true if the openid provider is in openid_providers list" do
    Chef::Config[:openid_providers] = [ 'monkeyid' ]   
    c = OpenidConsumer.new(true)
    c.send(:check_valid_openid_provider, "monkeyid").should eql(true)
  end
  
  it "should return true if the openid provider is in openid_providers list with http://" do
    Chef::Config[:openid_providers] = [ 'monkeyid' ]   
    c = OpenidConsumer.new(true)
    c.send(:check_valid_openid_provider, "http://monkeyid").should eql(true)
  end
  
  it "should raise an exception if the openid provider is not in openid_providers list" do
    Chef::Config[:openid_providers] = [ 'monkeyid' ]   
    c = OpenidConsumer.new(true)
    lambda {  
      c.send(:check_valid_openid_provider, "monkey") 
    }.should raise_error(Merb::Controller::Unauthorized)    
  end
end