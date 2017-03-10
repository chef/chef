#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright 2015-2016, Chef Software, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

require "chef/key"

describe Chef::Key do
  # whether user or client irrelevent to these tests
  let(:key) { Chef::Key.new("original_actor", "user") }
  let(:public_key_string) do
    <<EOS
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvPo+oNPB7uuNkws0fC02
KxSwdyqPLu0fhI1pOweNKAZeEIiEz2PkybathHWy8snSXGNxsITkf3eyvIIKa8OZ
WrlqpI3yv/5DOP8HTMCxnFuMJQtDwMcevlqebX4bCxcByuBpNYDcAHjjfLGSfMjn
E5lZpgYWwnpic4kSjYcL9ORK9nYvlWV9P/kCYmRhIjB4AhtpWRiOfY/TKi3P2LxT
IjSmiN/ihHtlhV/VSnBJ5PzT/lRknlrJ4kACoz7Pq9jv+aAx5ft/xE9yDa2DYs0q
Tfuc9dUYsFjptWYrV6pfEQ+bgo1OGBXORBFcFL+2D7u9JYquKrMgosznHoEkQNLo
0wIDAQAB
-----END PUBLIC KEY-----
EOS
  end

  shared_examples_for "fields with username type validation" do
    context "when invalid input is passed" do
      # It is not feasible to check all invalid characters.  Here are a few
      # that we probably care about.
      it "should raise an ArgumentError" do
        # capital letters
        expect { key.send(field, "Bar") }.to raise_error(ArgumentError)
        # slashes
        expect { key.send(field, "foo/bar") }.to raise_error(ArgumentError)
        # ?
        expect { key.send(field, "foo?") }.to raise_error(ArgumentError)
        # &
        expect { key.send(field, "foo&") }.to raise_error(ArgumentError)
        # spaces
        expect { key.send(field, "foo ") }.to raise_error(ArgumentError)
      end
    end
  end

  shared_examples_for "string fields that are settable" do
    context "when it is set with valid input" do
      it "should set the field" do
        key.send(field, valid_input)
        expect(key.send(field)).to eq(valid_input)
      end
    end

    context "when you feed it anything but a string" do
      it "should raise an ArgumentError" do
        expect { key.send(field, Hash.new) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "when a new Chef::Key object is initialized with invalid input" do
    it "should raise an InvalidKeyArgument" do
      expect { Chef::Key.new("original_actor", "not_a_user_or_client") }.to raise_error(Chef::Exceptions::InvalidKeyArgument)
    end
  end

  describe "when a new Chef::Key object is initialized with valid input" do
    it "should be a Chef::Key" do
      expect(key).to be_a_kind_of(Chef::Key)
    end

    it "should properly set the actor" do
      expect(key.actor).to eq("original_actor")
    end
  end

  describe "when actor field is set" do
    it_should_behave_like "string fields that are settable" do
      let(:field) { :actor }
      let(:valid_input) { "new_field_value" }
    end

    it_should_behave_like "fields with username type validation" do
      let(:field) { :actor }
    end
  end

  describe "when the name field is set" do
    it_should_behave_like "string fields that are settable" do
      let(:field) { :name }
      let(:valid_input) { "new_field_value" }
    end
  end

  describe "when the private_key field is set" do
    it_should_behave_like "string fields that are settable" do
      let(:field) { :private_key }
      let(:valid_input) { "new_field_value" }
    end
  end

  describe "when the public_key field is set" do
    it_should_behave_like "string fields that are settable" do
      let(:field) { :public_key }
      let(:valid_input) { "new_field_value" }
    end

    context "when create_key is true" do
      before do
        key.create_key true
      end

      it "should raise an InvalidKeyAttribute" do
        expect { key.public_key public_key_string }.to raise_error(Chef::Exceptions::InvalidKeyAttribute)
      end
    end
  end

  describe "when the create_key field is set" do
    context "when it is set to true" do
      it "should set the field" do
        key.create_key(true)
        expect(key.create_key).to eq(true)
      end
    end

    context "when it is set to false" do
      it "should set the field" do
        key.create_key(false)
        expect(key.create_key).to eq(false)
      end
    end

    context "when anything but a TrueClass or FalseClass is passed" do
      it "should raise an ArgumentError" do
        expect { key.create_key "not_a_boolean" }.to raise_error(ArgumentError)
      end
    end

    context "when public_key is defined" do
      before do
        key.public_key public_key_string
      end

      it "should raise an InvalidKeyAttribute" do
        expect { key.create_key true }.to raise_error(Chef::Exceptions::InvalidKeyAttribute)
      end
    end
  end

  describe "when the expiration_date field is set" do
    context "when a valid date is passed" do
      it_should_behave_like "string fields that are settable" do
        let(:field) { :public_key }
        let(:valid_input) { "2020-12-24T21:00:00Z" }
      end
    end

    context "when infinity is passed" do
      it_should_behave_like "string fields that are settable" do
        let(:field) { :public_key }
        let(:valid_input) { "infinity" }
      end
    end

    context "when an invalid date is passed" do
      it "should raise an ArgumentError" do
        expect { key.expiration_date "invalid_date" }.to raise_error(ArgumentError)
        # wrong years
        expect { key.expiration_date "20-12-24T21:00:00Z" }.to raise_error(ArgumentError)
      end

      context "when it is a valid UTC date missing a Z" do
        it "should raise an ArgumentError" do
          expect { key.expiration_date "2020-12-24T21:00:00" }.to raise_error(ArgumentError)
        end
      end
    end
  end # when the expiration_date field is set

  describe "when serializing to JSON" do
    shared_examples_for "common json operations" do
      it "should serializes as a JSON object" do
        expect(json).to match(/^\{.+\}$/)
      end

      it "should include the actor value under the key relative to the actor_field_name passed" do
        expect(json).to include(%Q{"#{new_key.actor_field_name}":"original_actor"})
      end

      it "should include the name field when present" do
        new_key.name("monkeypants")
        expect(new_key.to_json).to include(%q{"name":"monkeypants"})
      end

      it "should not include the name if not present" do
        expect(json).to_not include("name")
      end

      it "should include the public_key field when present" do
        new_key.public_key "this_public_key"
        expect(new_key.to_json).to include(%q{"public_key":"this_public_key"})
      end

      it "should not include the public_key if not present" do
        expect(json).to_not include("public_key")
      end

      it "should include the private_key field when present" do
        new_key.private_key "this_public_key"
        expect(new_key.to_json).to include(%q{"private_key":"this_public_key"})
      end

      it "should not include the private_key if not present" do
        expect(json).to_not include("private_key")
      end

      it "should include the expiration_date field when present" do
        new_key.expiration_date "2020-12-24T21:00:00Z"
        expect(new_key.to_json).to include(%q{"expiration_date":"2020-12-24T21:00:00Z"})
      end

      it "should not include the expiration_date if not present" do
        expect(json).to_not include("expiration_date")
      end

      it "should include the create_key field when present" do
        new_key.create_key true
        expect(new_key.to_json).to include(%q{"create_key":true})
      end

      it "should not include the create_key if not present" do
        expect(json).to_not include("create_key")
      end
    end

    context "when key is for a user" do
      it_should_behave_like "common json operations" do
        let(:new_key) { Chef::Key.new("original_actor", "user") }
        let(:json) do
          new_key.to_json
        end
      end
    end

    context "when key is for a client" do
      it_should_behave_like "common json operations" do
        let(:new_key) { Chef::Key.new("original_actor", "client") }
        let(:json) do
          new_key.to_json
        end
      end
    end

  end # when serializing to JSON

  describe "when deserializing from JSON" do
    shared_examples_for "a deserializable object" do
      it "deserializes to a Chef::Key object" do
        expect(key).to be_a_kind_of(Chef::Key)
      end

      it "preserves the actor" do
        expect(key.actor).to eq("turtle")
      end

      it "preserves the name" do
        expect(key.name).to eq("key_name")
      end

      it "includes the public key if present" do
        expect(key.public_key).to eq(public_key_string)
      end

      it "includes the expiration_date if present" do
        expect(key.expiration_date).to eq("infinity")
      end

      it "includes the private_key if present" do
        expect(key.private_key).to eq("some_private_key")
      end

      it "includes the create_key if present" do
        expect(key_with_create_key_field.create_key).to eq(true)
      end
    end

    context "when deserializing a key for a user" do
      it_should_behave_like "a deserializable object" do
        let(:key) do
          o = { "user" => "turtle",
                "name" => "key_name",
                "public_key" => public_key_string,
                "private_key" => "some_private_key",
                "expiration_date" => "infinity" }
          Chef::Key.from_json(o.to_json)
        end
        let(:key_with_create_key_field) do
          o = { "user" => "turtle",
                "create_key" => true }
          Chef::Key.from_json(o.to_json)
        end
      end
    end

    context "when deserializing a key for a client" do
      it_should_behave_like "a deserializable object" do
        let(:key) do
          o = { "client" => "turtle",
                "name" => "key_name",
                "public_key" => public_key_string,
                "private_key" => "some_private_key",
                "expiration_date" => "infinity" }
          Chef::Key.from_json(o.to_json)
        end
        let(:key_with_create_key_field) do
          o = { "client" => "turtle",
                "create_key" => true }
          Chef::Key.from_json(o.to_json)
        end
      end
    end
  end # when deserializing from JSON

  describe "API Interactions" do
    let(:rest) do
      Chef::Config[:chef_server_root] = "http://www.example.com"
      Chef::Config[:chef_server_url] = "http://www.example.com/organizations/test_org"
      r = double("rest")
      allow(Chef::ServerAPI).to receive(:new).and_return(r)
      r
    end

    let(:user_key) do
      o = Chef::Key.new("foobar", "user")
      o
    end

    let(:client_key) do
      o = Chef::Key.new("foobar", "client")
      o
    end

    describe "list" do
      context "when listing keys for a user" do
        let(:response) { [{ "uri" => "http://www.example.com/users/keys/foobar", "name" => "foobar", "expired" => false }] }
        let(:inflated_response) { { "foobar" => user_key } }

        it "lists all keys" do
          expect(rest).to receive(:get).with("users/#{user_key.actor}/keys").and_return(response)
          expect(Chef::Key.list_by_user("foobar")).to eq(response)
        end

        it "inflate all keys" do
          allow(Chef::Key).to receive(:load_by_user).with(user_key.actor, "foobar").and_return(user_key)
          expect(rest).to receive(:get).with("users/#{user_key.actor}/keys").and_return(response)
          expect(Chef::Key.list_by_user("foobar", true)).to eq(inflated_response)
        end

      end

      context "when listing keys for a client" do
        let(:response) { [{ "uri" => "http://www.example.com/users/keys/foobar", "name" => "foobar", "expired" => false }] }
        let(:inflated_response) { { "foobar" => client_key } }

        it "lists all keys" do
          expect(rest).to receive(:get).with("clients/#{client_key.actor}/keys").and_return(response)
          expect(Chef::Key.list_by_client("foobar")).to eq(response)
        end

        it "inflate all keys" do
          allow(Chef::Key).to receive(:load_by_client).with(client_key.actor, "foobar").and_return(client_key)
          expect(rest).to receive(:get).with("clients/#{user_key.actor}/keys").and_return(response)
          expect(Chef::Key.list_by_client("foobar", true)).to eq(inflated_response)
        end

      end
    end

    describe "create" do
      shared_examples_for "create key" do
        context "when a field is missing" do
          it "should raise a MissingKeyAttribute" do
            expect { key.create }.to raise_error(Chef::Exceptions::MissingKeyAttribute)
          end
        end

        context "when the name field is missing" do
          before do
            key.public_key public_key_string
            key.expiration_date "2020-12-24T21:00:00Z"
          end

          it "creates a new key via the API with the fingerprint as the name" do
            expect(rest).to receive(:post).with(url,
                                                     { "name" => "12:3e:33:73:0b:f4:ec:72:dc:f0:4c:51:62:27:08:76:96:24:f4:4a",
                                                       "public_key" => key.public_key,
                                                       "expiration_date" => key.expiration_date }).and_return({})
            key.create
          end
        end

        context "when every field is populated" do
          before do
            key.name "key_name"
            key.public_key public_key_string
            key.expiration_date "2020-12-24T21:00:00Z"
            key.create_key false
          end

          context "when create_key is false" do
            it "creates a new key via the API" do
              expect(rest).to receive(:post).with(url,
                                                       { "name" => key.name,
                                                         "public_key" => key.public_key,
                                                         "expiration_date" => key.expiration_date }).and_return({})
              key.create
            end
          end

          context "when create_key is true and public_key is nil" do

            before do
              key.delete_public_key
              key.create_key true
              $expected_output = {
                actor_type => "foobar",
                "name" => key.name,
                "create_key" => true,
                "expiration_date" => key.expiration_date,
              }
              $expected_input = {
                "name" => key.name,
                "create_key" => true,
                "expiration_date" => key.expiration_date,
              }
            end

            it "should create a new key via the API" do
              expect(rest).to receive(:post).with(url, $expected_input).and_return({})
              key.create
            end

            context "when the server returns the private_key via key.create" do
              before do
                allow(rest).to receive(:post).with(url, $expected_input).and_return({ "private_key" => "this_private_key" })
              end

              it "key.create returns the original key plus the private_key" do
                expect(key.create.to_hash).to eq($expected_output.merge({ "private_key" => "this_private_key" }))
              end
            end
          end

          context "when create_key is false and public_key is nil" do
            before do
              key.delete_public_key
              key.create_key false
            end
            it "should raise an InvalidKeyArgument" do
              expect { key.create }.to raise_error(Chef::Exceptions::MissingKeyAttribute)
            end
          end
        end
      end

      context "when creating a user key" do
        it_should_behave_like "create key" do
          let(:url) { "users/#{key.actor}/keys" }
          let(:key) { user_key }
          let(:actor_type) { "user" }
        end
      end

      context "when creating a client key" do
        it_should_behave_like "create key" do
          let(:url) { "clients/#{client_key.actor}/keys" }
          let(:key) { client_key }
          let(:actor_type) { "client" }
        end
      end
    end # create

    describe "update" do
      shared_examples_for "update key" do
        context "when name is missing and no argument was passed to update" do
          it "should raise an MissingKeyAttribute" do
            expect { key.update }.to raise_error(Chef::Exceptions::MissingKeyAttribute)
          end
        end

        context "when some fields are populated" do
          before do
            key.name "key_name"
            key.expiration_date "2020-12-24T21:00:00Z"
          end

          it "should update the key via the API" do
            expect(rest).to receive(:put).with(url, key.to_hash).and_return({})
            key.update
          end
        end

        context "when @name is not nil and a arg is passed to update" do
          before do
            key.name "new_name"
          end

          it "passes @name in the body and the arg in the PUT URL" do
            expect(rest).to receive(:put).with(update_name_url, key.to_hash).and_return({})
            key.update("old_name")
          end
        end

        context "when the server returns a public_key and create_key is true" do
          before do
            key.name "key_name"
            key.create_key true
            allow(rest).to receive(:put).with(url, key.to_hash).and_return({
                                                                                  "key" => "key_name",
                                                                                  "public_key" => public_key_string,
                                                                                })

          end

          it "returns a key with public_key populated" do
            new_key = key.update
            expect(new_key.public_key).to eq(public_key_string)
          end

          it "returns a key without create_key set" do
            new_key = key.update
            expect(new_key.create_key).to be_nil
          end
        end
      end

      context "when updating a user key" do
        it_should_behave_like "update key" do
          let(:url) { "users/#{key.actor}/keys/#{key.name}" }
          let(:update_name_url) { "users/#{key.actor}/keys/old_name" }
          let(:key) { user_key }
        end
      end

      context "when updating a client key" do
        it_should_behave_like "update key" do
          let(:url) { "clients/#{client_key.actor}/keys/#{key.name}" }
          let(:update_name_url) { "clients/#{client_key.actor}/keys/old_name" }
          let(:key) { client_key }
        end
      end

    end #update

    describe "load" do
      shared_examples_for "load" do
        it "should load a named key from the API" do
          expect(rest).to receive(:get).with(url).and_return({ "user" => "foobar", "name" => "test_key_name", "public_key" => public_key_string, "expiration_date" => "infinity" })
          key = Chef::Key.send(load_method, "foobar", "test_key_name")
          expect(key.actor).to eq("foobar")
          expect(key.name).to eq("test_key_name")
          expect(key.public_key).to eq(public_key_string)
          expect(key.expiration_date).to eq("infinity")
        end
      end

      describe "load_by_user" do
        it_should_behave_like "load" do
          let(:load_method) { :load_by_user }
          let(:url) { "users/foobar/keys/test_key_name" }
        end
      end

      describe "load_by_client" do
        it_should_behave_like "load" do
          let(:load_method) { :load_by_client }
          let(:url) { "clients/foobar/keys/test_key_name" }
        end
      end

    end #load

    describe "destroy" do
      shared_examples_for "destroy key" do
        context "when name is missing" do
          it "should raise an MissingKeyAttribute" do
            expect { Chef::Key.new("username", "user").destroy }.to raise_error(Chef::Exceptions::MissingKeyAttribute)
          end
        end

        before do
          key.name "key_name"
        end
        context "when name is not missing" do
          it "should delete the key via the API" do
            expect(rest).to receive(:delete).with(url).and_return({})
            key.destroy
          end
        end
      end

      context "when destroying a user key" do
        it_should_behave_like "destroy key" do
          let(:url) { "users/#{key.actor}/keys/#{key.name}" }
          let(:key) { user_key }
        end
      end

      context "when destroying a client key" do
        it_should_behave_like "destroy key" do
          let(:url) { "clients/#{client_key.actor}/keys/#{key.name}" }
          let(:key) { client_key }
        end
      end
    end
  end # API Interactions
end
