require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a role exists" do
  request(resource(:roles), :method => "POST", 
    :params => { :role => { :id => nil }})
end

describe "resource(:roles)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:roles))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of roles" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a role exists" do
    before(:each) do
      @response = request(resource(:roles))
    end
    
    it "has a list of roles" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      @response = request(resource(:roles), :method => "POST", 
        :params => { :role => { :id => nil }})
    end
    
    it "redirects to resource(:roles)" do
    end
    
  end
end

describe "resource(@role)" do 
  describe "a successful DELETE", :given => "a role exists" do
     before(:each) do
       @response = request(resource(Role.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:roles))
     end

   end
end

describe "resource(:roles, :new)" do
  before(:each) do
    @response = request(resource(:roles, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@role, :edit)", :given => "a role exists" do
  before(:each) do
    @response = request(resource(Role.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@role)", :given => "a role exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Role.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @role = Role.first
      @response = request(resource(@role), :method => "PUT", 
        :params => { :role => {:id => @role.id} })
    end
  
    it "redirect to the role show action" do
      @response.should redirect_to(resource(@role))
    end
  end
  
end

