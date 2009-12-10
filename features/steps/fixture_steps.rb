
require 'ostruct'

Before do
  @fixtures = {
    'client' => {
      'isis' => Proc.new do
        c = Chef::ApiClient.new
        c.name "isis"
        c.create_keys
        c
      end,
      'isis_update' => {
        'name' => 'isis',
        'private_key' => true
      },
      'neurosis' => Proc.new do
        c = Chef::ApiClient.new
        c.name "neurosis"
        c.create_keys
        c
      end,
      'adminmonkey' => Proc.new do
        c = Chef::ApiClient.new
        c.name "adminmonkey"
        c.admin true
        c.create_keys
        c
      end
    },
    'signing_caller' =>{ 
      :user_id=>'bobo', :secret_key => "/tmp/poop.pem"
    },
    'registration' => { 
      'bobo' => Proc.new do
        OpenStruct.new({ :save => true })
      end,
      'not_admin' => Proc.new do
        OpenStruct.new({ :save => true })
      end
    },
    'data_bag' => {
      'users' => Proc.new do
        b = Chef::DataBag.new
        b.name "users"
        b
      end,
      'rubies' => Proc.new do
        b = Chef::DataBag.new
        b.name "rubies"
        b
      end
    },
    'data_bag_item' => {
      'francis' => Proc.new do
        i = Chef::DataBagItem.new
        i.data_bag "users"
        i.raw_data = { "id" => "francis" }
        i
      end,
      'francis_extra' => Proc.new do
        i = Chef::DataBagItem.new
        i.data_bag "users"
        i.raw_data = { "id" => "francis", "extra" => "majority" }
        i
      end,
      'axl_rose' => Proc.new do
        i = Chef::DataBagItem.new
        i.data_bag "users"
        i.raw_data = { "id" => "axl_rose" }
        i
      end
    },
    'role' => {
      'webserver' => Proc.new do
        r = Chef::Role.new
        r.name "webserver"
        r.description "monkey"
        r.recipes("role::webserver", "role::base")
        r.default_attributes({ 'a' => 'b' })
        r.override_attributes({ 'c' => 'd' })
        r 
      end,
      'db' => Proc.new do
        r = Chef::Role.new
        r.name "db"
        r.description "monkey"
        r.recipes("role::db", "role::base")
        r.default_attributes({ 'a' => 'bake' })
        r.override_attributes({ 'c' => 'down' })
        r 
      end
    },
    'node' => {
      'webserver' => Proc.new do
        n = Chef::Node.new
        n.name 'webserver'
        n.run_list << "tacos"
        n.snakes "on a plane"
        n.zombie "we're not unreasonable, I mean no-ones gonna eat your eyes"
        n
      end,
      'dbserver' => Proc.new do
        n = Chef::Node.new
        n.name 'dbserver'
        n.run_list << "oracle"
        n.just "kidding - who uses oracle?"
        n
      end,
      'searchman' => Proc.new do
        n = Chef::Node.new
        n.name 'searchman'
        n.run_list << "oracle"
        n.default_attrs = { "one" => "two", "three" => "four" }
        n.override_attrs = { "one" => "five" }
        n.set["walking"] = "tall"
        n
      end,
      'sync' => Proc.new do
        n = Chef::Node.new
        n.name 'sync'
        n.run_list << "node_cookbook_sync"
        n
      end
    },
    'hash' => {
      'nothing'   => Hash.new,
      'name only' => { :name => 'test_cookbook' }
    },
    'file' => {
      'blank file parameter' => {
        :file => nil
      },
      'string file parameter' => {
        :file => "just some text"
      },
      'original cookbook tarball' => {
        :file => File.new(File.join(datadir, "cookbook_tarballs", "original.tar.gz"), 'rb')
      },
      'new cookbook tarball' => {
        :file => File.new(File.join(datadir, "cookbook_tarballs", "new.tar.gz"), 'rb')
      },
      'not a tarball' => {
        :file => File.new(File.join(datadir, "cookbook_tarballs", "not_a_tarball.txt"), 'rb')
      },
      'empty tarball' => {
        :file => File.new(File.join(datadir, "cookbook_tarballs", "empty_tarball.tar.gz"), 'rb')
      }
    }
  }
  @stash = {}
end

def sign_request(http_method, private_key, user_id, body = "")
  timestamp = Time.now.utc.iso8601
  sign_obj = Mixlib::Auth::SignedHeaderAuth.signing_object(
                                                     :http_method=>http_method,
                                                     :body=>body,
                                                     :user_id=>user_id,
                                                     :timestamp=>timestamp)
  signed =  sign_obj.sign(private_key).merge({:host => "localhost"})
  signed.inject({}){|memo, kv| memo["#{kv[0].to_s.upcase}"] = kv[1];memo}
end

def get_fixture(stash_name, stash_key)
  fixy = @fixtures[stash_name][stash_key]
  if fixy.kind_of?(Proc)
    fixy.call
  else
    fixy
  end
end

Given /^an? '(.+)' named '(.+)'$/ do |stash_name, stash_key|
  # BUGBUG: I need to reference fixtures individually, but the fixtures, as written, store under the type, not the fixture's identifier and I don't currently have time to re-write the tests

  key = case stash_name
        when 'file','hash'
          stash_key
        else
          stash_name
        end
  @stash[key] = get_fixture(stash_name, stash_key)
end

Given /^an? '(.+)' named '(.+)' exists$/ do |stash_name, stash_key|  
  @stash[stash_name] = get_fixture(stash_name, stash_key) 
    
  if stash_name == 'registration'
    if stash_key == "bobo"
      r = Chef::REST.new(Chef::Config[:registration_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key])
      r.register("bobo", "#{tmpdir}/bobo.pem")
      c = Chef::ApiClient.cdb_load("bobo")
      c.admin(true)
      c.cdb_save
      @rest = Chef::REST.new(Chef::Config[:registration_url], 'bobo', "#{tmpdir}/bobo.pem")
    elsif stash_key == "not_admin"
      r = Chef::REST.new(Chef::Config[:registration_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key])
      r.register("not_admin", "#{tmpdir}/not_admin.pem")
      c = Chef::ApiClient.cdb_load("not_admin")
      c.cdb_save
      @rest = Chef::REST.new(Chef::Config[:registration_url], 'not_admin', "#{tmpdir}/not_admin.pem")
    end
  else 
    if @stash[stash_name].respond_to?(:cdb_save)
      @stash[stash_name].cdb_save
    elsif @stash[stash_name].respond_to?(:save)#stash_name == "registration" 
      @stash[stash_name].save
    else
      request("#{stash_name.pluralize}", { 
        :method => "POST", 
        "HTTP_ACCEPT" => 'application/json',
        "CONTENT_TYPE" => 'application/json',
        :input => @stash[stash_name].to_json 
      }.merge(sign_request("POST", OpenSSL::PKey::RSA.new(IO.read("#{tmpdir}/client.pem")), "bobo")))
    end
  end
end

Given /^sending the method '(.+)' to the '(.+)' with '(.+)'/ do |method, stash_name, update_value|
  update_value = JSON.parse(update_value) if update_value =~ /^\[|\{/
  @stash[stash_name].send(method.to_sym, update_value)
end

Given /^changing the '(.+)' field '(.+)' to '(.+)'$/ do |stash_name, stash_key, stash_value|
  @stash[stash_name].send(stash_key.to_sym, stash_value)
end

Given /^removing the '(.+)' field '(.+)'$/ do |stash_name, key|
  @stash[stash_name].send(key.to_sym, '')
end

Given /^there are no (.+)$/ do |stash_name|
end

Given /^I wait for '(\d+)' seconds$/ do |time|
  sleep time.to_i
end
