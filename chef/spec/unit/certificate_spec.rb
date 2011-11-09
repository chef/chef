#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

require 'chef/certificate'
require 'ostruct'
require 'tempfile'

class FakeFile
  attr_accessor :data

  def write(arg)
    @data = arg
  end
end

describe Chef::Certificate do
  describe "generate_signing_ca" do
    before(:each) do
      Chef::Config[:signing_ca_user] = nil
      Chef::Config[:signing_ca_group] = nil
      FileUtils.stub!(:mkdir_p).and_return(true)
      FileUtils.stub!(:chown).and_return(true)
      File.stub!(:open).and_return(true)
      File.stub!(:exists?).and_return(false)
      @ca_cert = FakeFile.new
      @ca_key = FakeFile.new
    end

    it "should generate a ca certificate" do
      File.should_receive(:open).with(Chef::Config[:signing_ca_cert], "w").and_yield(@ca_cert)
      Chef::Certificate.generate_signing_ca
      @ca_cert.data.should =~ /BEGIN CERTIFICATE/
    end

    it "should generate an RSA private key" do
      File.should_receive(:open).with(Chef::Config[:signing_ca_key], File::WRONLY|File::EXCL|File::CREAT, 0600).and_yield(@ca_key)
      FileUtils.should_not_receive(:chown)
      Chef::Certificate.generate_signing_ca
      @ca_key.data.should =~ /BEGIN RSA PRIVATE KEY/
    end

    it "should generate an RSA private key with user and group" do
      Chef::Config[:signing_ca_user] = "funky"
      Chef::Config[:signing_ca_group] = "fresh"
      File.should_receive(:open).with(Chef::Config[:signing_ca_key], File::WRONLY|File::EXCL|File::CREAT, 0600).and_yield(@ca_key)
      FileUtils.should_receive(:chown).with(Chef::Config[:signing_ca_user], Chef::Config[:signing_ca_group], Chef::Config[:signing_ca_key])
      Chef::Certificate.generate_signing_ca
      @ca_key.data.should =~ /BEGIN RSA PRIVATE KEY/
    end
  end

  describe "generate_keypair" do
    before(:each) do
      ca_cert = <<-EOH
-----BEGIN CERTIFICATE-----
MIID/jCCA2egAwIBAwIBATANBgkqhkiG9w0BAQUFADCBsDELMAkGA1UEBhMCVVMx
EzARBgNVBAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUxEjAQBgNVBAoM
CUNoZWYgVXNlcjEcMBoGA1UECwwTQ2VydGlmaWNhdGUgU2VydmljZTFIMEYGA1UE
Aww/b3BlbnNvdXJjZS5vcHNjb2RlLmNvbS9lbWFpbEFkZHJlc3M9b3BlbnNvdXJj
ZS1jZXJ0QG9wc2NvZGUuY29tMB4XDTA5MDkwNTAzNDAwNVoXDTE5MDkwMzAzNDAw
NVowgbAxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApXYXNoaW5ndG9uMRAwDgYDVQQH
DAdTZWF0dGxlMRIwEAYDVQQKDAlDaGVmIFVzZXIxHDAaBgNVBAsME0NlcnRpZmlj
YXRlIFNlcnZpY2UxSDBGBgNVBAMMP29wZW5zb3VyY2Uub3BzY29kZS5jb20vZW1h
aWxBZGRyZXNzPW9wZW5zb3VyY2UtY2VydEBvcHNjb2RlLmNvbTCBnzANBgkqhkiG
9w0BAQEFAAOBjQAwgYkCgYEAxrx/G4VqwFERbugpLefGJSdFE4rB+Xgr98V8joow
3wFWdxTMtj/DWa+2TCFjKdq5JZ6XLfDS/ddSvjLH5fBpR0TXRUfBE3vsGTujBcHm
g0Or9lXzaV9TcouxMCn2quPLhGCcWZ+ZllMH5M4GHjMWqV3xXtE3v0Kz2TFbe+Xt
ri8CAwEAAaOCASQwggEgMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOOd0lUe
6kc2nTAvQ75bkAcls4drMA4GA1UdDwEB/wQEAwIBBjCB3QYDVR0jBIHVMIHSgBTj
ndJVHupHNp0wL0O+W5AHJbOHa6GBtqSBszCBsDELMAkGA1UEBhMCVVMxEzARBgNV
BAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUxEjAQBgNVBAoMCUNoZWYg
VXNlcjEcMBoGA1UECwwTQ2VydGlmaWNhdGUgU2VydmljZTFIMEYGA1UEAww/b3Bl
bnNvdXJjZS5vcHNjb2RlLmNvbS9lbWFpbEFkZHJlc3M9b3BlbnNvdXJjZS1jZXJ0
QG9wc2NvZGUuY29tggEBMA0GCSqGSIb3DQEBBQUAA4GBAE3wtfHrBva3XtDOHKD3
A4PH+Yk3q+pilNfxNlhNv4CleO7P/8M1rbEuVdA6bv9mfFmN+H9GvS+isOcrVqdu
K4G8Qjl33KE+O80o51cio7zBCDBVnsG6nOp4bm40No0HWrSG473lPT8miViNY+7r
pahRFuBFIJ7nZMFO7BDIEwPC
-----END CERTIFICATE-----
EOH
    ca_key = <<-EOH
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQDGvH8bhWrAURFu6Ckt58YlJ0UTisH5eCv3xXyOijDfAVZ3FMy2
P8NZr7ZMIWMp2rklnpct8NL911K+Msfl8GlHRNdFR8ETe+wZO6MFweaDQ6v2VfNp
X1Nyi7EwKfaq48uEYJxZn5mWUwfkzgYeMxapXfFe0Te/QrPZMVt75e2uLwIDAQAB
AoGARKqUcHnkrJZWI6/rqoTOnb+3ykzDQOMYrf96TfXJdQQNUA/Lu5zEbpSbtCpF
DQ0Zs7ncGm9/N13SpQz+rKAof27lQcDuPq+XPwPlSSyFySWY0fYDrpeJ5HcHwE4u
DQmhvjPzmxW95MSXbnpoGyuIbrlrmLTq+cYiZ88MBFWiiSECQQD34h7JkziOWNP9
Mw6WAaUPDF9TNJPfA8f6L9ZqjTUa98CrXY1JEK71IdM4Atku8R2VZS+//x0M80y+
nWwukCWzAkEAzT5m9ExWxP1Uw79c2scvBhFq+lxhJ5SsrvEw+ysbtNpeZGnnxblO
zlFMwqmfU/eqbDlQTKVoFmlW2BYR3kTPlQJAelQWyXdj06u2gh+uNQz+vdxnNpKd
3tLo32i4McEZ0gMuC+ORE9ut278jk2Kkd2v6I33aALAPUBLJbtAVUS1FzQJBALJ2
FR1NF5GX2VGPnlSZJzk2gfeJxeydqP1AuV9cH25FBhh3wdE6DNz28jC9Ps3LJwON
XlYW6Qe7toiTwButZ3UCQB8HMYfQIeXi20bm1qetNt27jDOAzTBpxXxl06IF7eGH
L/6ibP7K+s7XkaVsnPcJ9DieBTR8asUo8O1QFG1uydM=
-----END RSA PRIVATE KEY-----
EOH
      File.stub!(:read).with(Chef::Config[:signing_ca_cert]).and_return(ca_cert)
      File.stub!(:read).with(Chef::Config[:signing_ca_key]).and_return(ca_key)
    end

    it "should return a client certificate" do
      cert, key = Chef::Certificate.gen_keypair("oasis")
      cert.to_s.should =~ /BEGIN RSA PUBLIC KEY/
      key.to_s.should =~ /BEGIN RSA PRIVATE KEY/
    end
  end
end
