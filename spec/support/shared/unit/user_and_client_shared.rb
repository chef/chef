#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

shared_examples_for "user or client create" do

  context "when server API V1 is valid on the Chef Server receiving the request" do

    it "creates a new object via the API" do
      expect(rest_v1).to receive(:post).with(url, payload).and_return({})
      object.create
    end

    it "creates a new object via the API with a public_key when it exists" do
      object.public_key "some_public_key"
      expect(rest_v1).to receive(:post).with(url, payload.merge({ :public_key => "some_public_key" })).and_return({})
      object.create
    end

    context "raise error when create_key and public_key are both set" do

      before do
        object.public_key "key"
        object.create_key true
      end

      it "rasies the proper error" do
        expect { object.create }.to raise_error(error)
      end
    end

    context "when create_key == true" do
      before do
        object.create_key true
      end

      it "creates a new object via the API with create_key" do
        expect(rest_v1).to receive(:post).with(url, payload.merge({ :create_key => true })).and_return({})
        object.create
      end
    end

    context "when chef_key is returned by the server" do
      let(:chef_key) do
        {
          "chef_key" => {
            "public_key" => "some_public_key",
          },
        }
      end

      it "puts the public key into the objectr returned by create" do
        expect(rest_v1).to receive(:post).with(url, payload).and_return(payload.merge(chef_key))
        new_object = object.create
        expect(new_object.public_key).to eq("some_public_key")
      end

      context "when private_key is returned in chef_key" do
        let(:chef_key) do
          {
            "chef_key" => {
              "public_key" => "some_public_key",
              "private_key" => "some_private_key",
            },
          }
        end

        it "puts the private key into the object returned by create" do
          expect(rest_v1).to receive(:post).with(url, payload).and_return(payload.merge(chef_key))
          new_object = object.create
          expect(new_object.private_key).to eq("some_private_key")
        end
      end
    end # when chef_key is returned by the server

  end # when server API V1 is valid on the Chef Server receiving the request

  context "when server API V1 is not valid on the Chef Server receiving the request" do

    context "when the server supports API V0" do
      before do
        allow(object).to receive(:server_client_api_version_intersection).and_return([0])
        allow(rest_v1).to receive(:post).and_raise(exception_406)
      end

      it "creates a new object via the API" do
        expect(rest_v0).to receive(:post).with(url, payload).and_return({})
        object.create
      end

      it "creates a new object via the API with a public_key when it exists" do
        object.public_key "some_public_key"
        expect(rest_v0).to receive(:post).with(url, payload.merge({ :public_key => "some_public_key" })).and_return({})
        object.create
      end

    end # when the server supports API V0
  end # when server API V1 is not valid on the Chef Server receiving the request

end # user or client create
