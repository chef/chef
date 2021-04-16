#
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::WindowsCertificate do
  let(:resource) { Chef::Resource::WindowsCertificate.new("foobar") }

  it "sets resource name as :windows_certificate" do
    expect(resource.resource_name).to eql(:windows_certificate)
  end

  it "the source property is the name_property" do
    expect(resource.source).to eql("foobar")
  end

  it "the store_name property defaults to 'MY'" do
    expect(resource.store_name).to eql("MY")
  end

  it 'the store_name property accepts "TRUSTEDPUBLISHER", "TrustedPublisher", "CLIENTAUTHISSUER", "REMOTE DESKTOP", "ROOT", "TRUSTEDDEVICES", "WEBHOSTING", "CA", "AUTHROOT", "TRUSTEDPEOPLE", "MY", "SMARTCARDROOT", "TRUST", or "DISALLOWED"' do
    expect { resource.store_name("TRUSTEDPUBLISHER") }.not_to raise_error
    expect { resource.store_name("TrustedPublisher") }.not_to raise_error
    expect { resource.store_name("CLIENTAUTHISSUER") }.not_to raise_error
    expect { resource.store_name("REMOTE DESKTOP") }.not_to raise_error
    expect { resource.store_name("ROOT") }.not_to raise_error
    expect { resource.store_name("TRUSTEDDEVICES") }.not_to raise_error
    expect { resource.store_name("WEBHOSTING") }.not_to raise_error
    expect { resource.store_name("CA") }.not_to raise_error
    expect { resource.store_name("AUTHROOT") }.not_to raise_error
    expect { resource.store_name("TRUSTEDPEOPLE") }.not_to raise_error
    expect { resource.store_name("MY") }.not_to raise_error
    expect { resource.store_name("SMARTCARDROOT") }.not_to raise_error
    expect { resource.store_name("TRUST") }.not_to raise_error
    expect { resource.store_name("DISALLOWED") }.not_to raise_error
  end

  it "the resource is marked sensitive if pfx_password is specified" do
    resource.pfx_password("1234")
    expect(resource.sensitive).to be true
  end

  it "the user_store property defaults to false" do
    expect(resource.user_store).to be false
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :acl_add, :delete, and :verify actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :acl_add }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :verify }.not_to raise_error
  end

  it "sets sensitive to true if the pfx_password property is set" do
    resource.pfx_password "foo"
    expect(resource.sensitive).to be_truthy
  end

  it "doesn't raise error if pfx_password contains special characters" do
    resource.pfx_password "chef$123"
    resource.source "C:\\certs\\test-cert.pfx"
    resource.store_name "MY"
    expect { resource.action :create }.not_to raise_error
  end

  it "the exportable property defaults to false" do
    expect(resource.exportable).to be false
  end

  it "doesn't raise error if exportable option is passed" do
    resource.pfx_password "chef$123"
    resource.source "C:\\certs\\test-cert.pfx"
    resource.store_name "MY"
    resource.exportable true
    expect { resource.action :create }.not_to raise_error
  end
end
