require File.join( File.dirname(__FILE__), "..", "spec_helper" )
require File.join( File.dirname(__FILE__), "..", "ident_spec_helper")
require File.join( File.dirname(__FILE__), "..", "authenticated_system_spec_helper")

describe Ident do
  include IdentSpecHelper
  
  before(:each) do
    Ident.clear_database_table
  end

  it "should have a login field" do
    ident = Ident.new
    ident.should respond_to(:login)
    ident.valid?
    ident.errors.on(:login).should_not be_nil
  end
  
  it "should fail login if there are less than 3 chars" do
    ident = Ident.new
    ident.login = "AB"
    ident.valid?
    ident.errors.on(:login).should_not be_nil
  end
  
  it "should not fail login with between 3 and 40 chars" do
    ident = Ident.new
    [3,40].each do |num|
      ident.login = "a" * num
      ident.valid?
      ident.errors.on(:login).should be_nil
    end
  end
  
  it "should fail login with over 90 chars" do
    ident = Ident.new
    ident.login = "A" * 41
    ident.valid?
    ident.errors.on(:login).should_not be_nil    
  end
  
  it "should make a valid ident" do
    ident = Ident.new(valid_ident_hash)
    ident.save
    ident.errors.should be_empty
    
  end
  
  it "should make sure login is unique" do
    ident = Ident.new( valid_ident_hash.with(:login => "Daniel") )
    ident2 = Ident.new( valid_ident_hash.with(:login => "Daniel"))
    ident.save.should be_true
    ident.login = "Daniel"
    ident2.save.should be_false
    ident2.errors.on(:login).should_not be_nil
  end
  
  it "should make sure login is unique regardless of case" do
    Ident.find_with_conditions(:login => "Daniel").should be_nil
    ident = Ident.new( valid_ident_hash.with(:login => "Daniel") )
    ident2 = Ident.new( valid_ident_hash.with(:login => "daniel"))
    ident.save.should be_true
    ident.login = "Daniel"
    ident2.save.should be_false
    ident2.errors.on(:login).should_not be_nil
  end
  
  it "should downcase logins" do
    ident = Ident.new( valid_ident_hash.with(:login => "DaNieL"))
    ident.login.should == "daniel"    
  end  
  
  it "should authenticate a ident using a class method" do
    ident = Ident.new(valid_ident_hash)
    ident.save
    Ident.authenticate(valid_ident_hash[:login], valid_ident_hash[:password]).should_not be_nil
  end
  
  it "should not authenticate a ident using the wrong password" do
    ident = Ident.new(valid_ident_hash)  
    ident.save
    Ident.authenticate(valid_ident_hash[:login], "not_the_password").should be_nil
  end
  
  it "should not authenticate a ident using the wrong login" do
    ident = Ident.create(valid_ident_hash)  
    Ident.authenticate("not_the_login", valid_ident_hash[:password]).should be_nil
  end
  
  it "should not authenticate a ident that does not exist" do
    Ident.authenticate("i_dont_exist", "password").should be_nil
  end
  
  
end

describe Ident, "the password fields for Ident" do
  include IdentSpecHelper
  
  before(:each) do
    Ident.clear_database_table
    @ident = Ident.new( valid_ident_hash )
  end
  
  it "should respond to password" do
    @ident.should respond_to(:password)    
  end
  
  it "should respond to password_confirmation" do
    @ident.should respond_to(:password_confirmation)
  end
  
  it "should have a protected password_required method" do
    @ident.protected_methods.should include("password_required?")
  end
  
  it "should respond to crypted_password" do
    @ident.should respond_to(:crypted_password)    
  end
  
  it "should require password if password is required" do
    ident = Ident.new( valid_ident_hash.without(:password))
    ident.stub!(:password_required?).and_return(true)
    ident.valid?
    ident.errors.on(:password).should_not be_nil
    ident.errors.on(:password).should_not be_empty
  end
  
  it "should set the salt" do
    ident = Ident.new(valid_ident_hash)
    ident.salt.should be_nil
    ident.send(:encrypt_password)
    ident.salt.should_not be_nil    
  end
  
  it "should require the password on create" do
    ident = Ident.new(valid_ident_hash.without(:password))
    ident.save
    ident.errors.on(:password).should_not be_nil
    ident.errors.on(:password).should_not be_empty
  end  
  
  it "should require password_confirmation if the password_required?" do
    ident = Ident.new(valid_ident_hash.without(:password_confirmation))
    ident.save
    (ident.errors.on(:password) || ident.errors.on(:password_confirmation)).should_not be_nil
  end
  
  it "should fail when password is outside 4 and 40 chars" do
    [3,41].each do |num|
      ident = Ident.new(valid_ident_hash.with(:password => ("a" * num)))
      ident.valid?
      ident.errors.on(:password).should_not be_nil
    end
  end
  
  it "should pass when password is within 4 and 40 chars" do
    [4,30,40].each do |num|
      ident = Ident.new(valid_ident_hash.with(:password => ("a" * num), :password_confirmation => ("a" * num)))
      ident.valid?
      ident.errors.on(:password).should be_nil
    end    
  end
  
  it "should autenticate against a password" do
    ident = Ident.new(valid_ident_hash)
    ident.save    
    ident.should be_authenticated(valid_ident_hash[:password])
  end
  
  it "should not require a password when saving an existing ident" do
    ident = Ident.create(valid_ident_hash)
    ident = Ident.find_with_conditions(:login => valid_ident_hash[:login])
    ident.password.should be_nil
    ident.password_confirmation.should be_nil
    ident.login = "some_different_login_to_allow_saving"
    (ident.save).should be_true
  end
  
end


describe Ident, "remember_me" do
  include IdentSpecHelper
  
  predicate_matchers[:remember_token] = :remember_token?
  
  before do
    Ident.clear_database_table
    @ident = Ident.new(valid_ident_hash)
  end
  
  it "should have a remember_token_expires_at attribute" do
    @ident.attributes.keys.any?{|a| a.to_s == "remember_token_expires_at"}.should_not be_nil
  end  
  
  it "should respond to remember_token?" do
    @ident.should respond_to(:remember_token?)
  end
  
  it "should return true if remember_token_expires_at is set and is in the future" do
    @ident.remember_token_expires_at = DateTime.now + 3600
    @ident.should remember_token    
  end
  
  it "should set remember_token_expires_at to a specific date" do
    time = Time.mktime(2009,12,25)
    @ident.remember_me_until(time)
    @ident.remember_token_expires_at.should == time    
  end
  
  it "should set the remember_me token when remembering" do
    time = Time.mktime(2009,12,25)
    @ident.remember_me_until(time)
    @ident.remember_token.should_not be_nil
    @ident.save
    Ident.find_with_conditions(:login => valid_ident_hash[:login]).remember_token.should_not be_nil
  end
  
  it "should remember me for" do
    t = Time.now
    Time.stub!(:now).and_return(t)
    today = Time.now
    remember_until = today + (2* Merb::Const::WEEK)
    @ident.remember_me_for( Merb::Const::WEEK * 2)
    @ident.remember_token_expires_at.should == (remember_until)
  end
  
  it "should remember_me for two weeks" do
    t = Time.now
    Time.stub!(:now).and_return(t)
    @ident.remember_me
    @ident.remember_token_expires_at.should == (Time.now + (2 * Merb::Const::WEEK ))
  end
  
  it "should forget me" do
    @ident.remember_me
    @ident.save
    @ident.forget_me
    @ident.remember_token.should be_nil
    @ident.remember_token_expires_at.should be_nil    
  end
  
  it "should persist the forget me to the database" do
    @ident.remember_me
    @ident.save
    
    @ident = Ident.find_with_conditions(:login => valid_ident_hash[:login])
    @ident.remember_token.should_not be_nil
    
    @ident.forget_me

    @ident = Ident.find_with_conditions(:login => valid_ident_hash[:login])
    @ident.remember_token.should be_nil
    @ident.remember_token_expires_at.should be_nil
  end
  
end