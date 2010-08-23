
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
    'sandbox' => {
      # The filename part of these 'checksums' hashes isn't used by the API (the 
      # value side of that hash is ignored), and is here for documentation's sake.
      'sandbox1' => {
        :checksums => {
          Chef::CookbookVersion.checksum_cookbook_file(File.join(datadir, "cookbooks_not_uploaded_at_feature_start", "test_cookbook", "recipes", "default.rb")) => nil
        },
      },
      'sandbox2' => {
        :checksums => {
          Chef::CookbookVersion.checksum_cookbook_file(File.join(datadir, "cookbooks_not_uploaded_at_feature_start", "test_cookbook", "attributes", "attr1.rb")) => nil,
          Chef::CookbookVersion.checksum_cookbook_file(File.join(datadir, "cookbooks_not_uploaded_at_feature_start", "test_cookbook", "attributes", "attr2.rb")) => nil
        },
      },
    },
    'sandbox_file' => {
      "sandbox1_file1" => File.join(datadir, "cookbooks_not_uploaded_at_feature_start", "test_cookbook", "recipes", "default.rb"),

      "sandbox2_file1" => File.join(datadir, "cookbooks_not_uploaded_at_feature_start", "test_cookbook", "attributes", "attr1.rb"),
      "sandbox2_file2" => File.join(datadir, "cookbooks_not_uploaded_at_feature_start", "test_cookbook", "attributes", "attr2.rb"),
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
      end,
      'role_not_exist' => Proc.new do
        r = Chef::Role.new
        r.name 'role_not_exist'
        r.description "Non-existent nested role"
        r.run_list << "role[not_exist]"
        r
      end,
      'attribute_settings_default' => Proc.new do
        r = Chef::Role.new
        r.name "attribute_settings_default"
        r.description "sets a default value"
        r.run_list("recipe[attribute_settings]")
        r.default_attributes({ 'attribute_priority_was' => 2 })
        r 
      end,
      'attribute_settings_override' => Proc.new do
        r = Chef::Role.new
        r.name "attribute_settings_override"
        r.description "sets a default value"
        r.run_list("recipe[attribute_settings_override]")
        r.override_attributes({ 'attribute_priority_was' => 7 })
        r
      end,
      'role1_includes_role2' => Proc.new do
        r = Chef::Role.new
        r.name "role1_includes_role2"
        r.description "role1 includes role2"
        r.run_list("role[role2_included_by_role1]")
        r
      end,
      'role2_included_by_role1' => Proc.new do
        r = Chef::Role.new
        r.name "role2_included_by_role1"
        r.description "role2 is included by role1"
        r.run_list("recipe[attribute_settings_override]")
        r
      end
    },
    'node' => {
      'opsmaster' => Proc.new do
        n = Chef::Node.new
        n.name 'opsmaster'
        n.chef_environment 'production'
        n.snakes "on a plane"
        n.zombie "we're not unreasonable, I mean no-ones gonna eat your eyes"
        n
      end,
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
      end, 
      'role_not_exist' => Proc.new do
        n = Chef::Node.new
        n.name 'role_not_exist'
        n.run_list << "role[not_exist]"
        n
      end,
      'paradise' => Proc.new do
        n = Chef::Node.new
        n.name 'paradise'
        n.run_list << "version_test"
        n
      end,
      'has_environment' => Proc.new do
        n = Chef::Node.new
        n.name 'has_environment'
        n.chef_environment 'cookbooks_test'
        n.run_list << "version_test"
        n
      end
    },
    'hash' => {
      'nothing'   => Hash.new,
      'name only' => { :name => 'test_cookbook' }
    },
    'environment' => {
      'cucumber' => Proc.new do
        e = Chef::Environment.new
        e.name 'cucumber'
        e.description 'I like to run tests'
        e
      end,
      'production' => Proc.new do
        e = Chef::Environment.new
        e.name 'production'
        e.description 'The real deal'
        e
      end,
      'cookbooks-0.1.0' => Proc.new do
        e = Chef::Environment.new
        e.name 'cookbooks_test'
        e.description 'use cookbook version 0.1.0'
        e.cookbook 'version_test', '0.1.0'
        e
      end,
      'cookbooks-0.1.1' => Proc.new do
        e = Chef::Environment.new
        e.name 'cookbooks_test'
        e.description 'use cookbook version 0.1.1'
        e.cookbook 'version_test', '0.1.1'
        e
      end,
      'cookbooks-0.2.0' => Proc.new do
        e = Chef::Environment.new
        e.name 'cookbooks_test'
        e.description 'use cookbook version 0.2.0'
        e.cookbook 'version_test', '0.2.0'
        e
      end
    }
  }
  @stash = {}
end

def sign_request(http_method, path, private_key, user_id, body = "")
  timestamp = Time.now.utc.iso8601
  sign_obj = Mixlib::Auth::SignedHeaderAuth.signing_object(
                                                     :http_method=>http_method,
                                                     :path=>path,
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

Given "I am a non admin client" do
  r = Chef::REST.new(Chef::Config[:registration_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key])
  r.register("not_admin", "#{tmpdir}/not_admin.pem")
  c = Chef::ApiClient.cdb_load("not_admin")
  c.cdb_save
  @rest = Chef::REST.new(Chef::Config[:registration_url], 'not_admin', "#{tmpdir}/not_admin.pem")
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

Given "I am an administrator" do
  make_admin
end

Given "I am a non-admin" do
  make_non_admin
end

Given /^an? '(.+)' named '(.+)' exists$/ do |stash_name, stash_key|  
  call_as_admin do
    @stash[stash_name] = get_fixture(stash_name, stash_key)

    #if @stash[stash_name].respond_to?(:cdb_save)
    #  @stash[stash_name].cdb_save
    if @stash[stash_name].respond_to?(:save)
      @stash[stash_name].save
    else
      request_path = "/#{stash_name.pluralize}"
      request(request_path, {
        :method => "POST",
        "HTTP_ACCEPT" => 'application/json',
        "CONTENT_TYPE" => 'application/json',
        :input => @stash[stash_name].to_json
      }.merge(sign_request("POST", request_path, OpenSSL::PKey::RSA.new(IO.read("#{tmpdir}/client.pem")), "bobo")))
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
