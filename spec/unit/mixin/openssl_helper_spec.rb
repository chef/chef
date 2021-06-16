#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "spec_helper"
require "chef/mixin/openssl_helper"

describe Chef::Mixin::OpenSSLHelper do
  let(:instance) do
    Class.new { include Chef::Mixin::OpenSSLHelper }.new
  end

  # Path helpers
  describe "#get_key_filename" do
    context "When the input is not a string" do
      it "Throws a TypeError" do
        expect do
          instance.get_key_filename(33)
        end.to raise_error(TypeError)
      end
    end

    context "when the input is a string" do
      it "Generates valid keyfile names" do
        expect(instance.get_key_filename("/etc/temp.crt")).to match("/etc/temp.key")
      end
    end
  end

  # Validation helpers
  describe "#key_length_valid?" do
    context "When the number is less than 1024" do
      it "returns false" do
        expect(instance.key_length_valid?(1023)).to be_falsey
        expect(instance.key_length_valid?(2)).to be_falsey
        expect(instance.key_length_valid?(64)).to be_falsey
        expect(instance.key_length_valid?(512)).to be_falsey
      end
    end

    context "When the number is greater than 1024 but is not a power of 2" do
      it "returns false" do
        expect(instance.key_length_valid?(1025)).to be_falsey
        expect(instance.key_length_valid?(6666)).to be_falsey
        expect(instance.key_length_valid?(8191)).to be_falsey
      end
    end

    context "When the number is a power of 2, equal to or greater than 1024" do
      it "returns true" do
        expect(instance.key_length_valid?(1024)).to be_truthy
        expect(instance.key_length_valid?(2048)).to be_truthy
        expect(instance.key_length_valid?(4096)).to be_truthy
        expect(instance.key_length_valid?(8192)).to be_truthy
      end
    end
  end

  describe "#dhparam_pem_valid?" do
    require "tempfile"

    before(:each) do
      @dhparam_file = Tempfile.new("dhparam")
    end

    context "When the dhparam.pem file does not exist" do
      it "returns false" do
        expect(instance.dhparam_pem_valid?("/tmp/bad_filename")).to be_falsey
      end
    end

    context "When the dhparam.pem file does exist, but does not contain a valid dhparam key" do
      it "Throws an OpenSSL::PKey::DHError exception" do
        expect do
          @dhparam_file.puts("I_am_not_a_key_I_am_a_free_man")
          @dhparam_file.close
          instance.dhparam_pem_valid?(@dhparam_file.path)
        end.to raise_error(::OpenSSL::PKey::DHError)
      end
    end

    context "When the dhparam.pem file does exist, and does contain a vaild dhparam key" do
      it "returns true" do
        @dhparam_file.puts(::OpenSSL::PKey::DH.new(256).to_pem) # this is 256 to speed up specs
        @dhparam_file.close
        expect(instance.dhparam_pem_valid?(@dhparam_file.path)).to be_truthy
      end
    end

    after(:each) do
      @dhparam_file.unlink
    end
  end

  describe "#priv_key_file_valid?" do
    require "tempfile"
    require "openssl" unless defined?(OpenSSL)

    cipher = ::OpenSSL::Cipher.new("des3")

    before(:each) do
      @keyfile = Tempfile.new("keyfile")
    end

    context "When the key file does not exist" do
      it "returns false" do
        expect(instance.priv_key_file_valid?("/tmp/bad_filename")).to be_falsey
      end
    end

    context "When the key file does exist, but does not contain a valid rsa/ec private key" do
      it "Throws an OpenSSL::PKey::PKeyError exception" do
        @keyfile.write("I_am_not_a_key_I_am_a_free_man")
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path)).to be_falsey
      end
    end

    context "When the rsa key file does exist, and does contain a vaild rsa private key" do
      it "returns true" do
        @keyfile.write(::OpenSSL::PKey::RSA.new(1024).to_pem)
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path)).to be_truthy
      end
    end

    context "When the ec key file does exist, and does contain a vaild ec private key" do
      it "returns true" do
        @keyfile.write(OpenSSL::PKey::EC.generate("prime256v1").to_pem)
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path)).to be_truthy
      end
    end

    context "When a valid rsa keyfile requires a passphrase, and an invalid passphrase is supplied" do
      it "returns false" do
        @keyfile.write(OpenSSL::PKey::RSA.new(1024).to_pem(cipher, "oink"))
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path, "poml")).to be_falsey
      end
    end

    context "When a valid ec keyfile requires a passphrase, and an invalid passphrase is supplied" do
      it "returns false" do
        @keyfile.write(OpenSSL::PKey::EC.generate("prime256v1").to_pem(cipher, "oink"))
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path, "poml")).to be_falsey
      end
    end

    context "When a valid rsa keyfile requires a passphrase, and a valid passphrase is supplied" do
      it "returns true" do
        @keyfile.write(OpenSSL::PKey::RSA.new(1024).to_pem(cipher, "oink"))
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path, "oink")).to be_truthy
      end
    end

    context "When a valid ec keyfile requires a passphrase, and a valid passphrase is supplied" do
      it "returns true" do
        @keyfile.write(OpenSSL::PKey::EC.generate("prime256v1").to_pem(cipher, "oink"))
        @keyfile.close
        expect(instance.priv_key_file_valid?(@keyfile.path, "oink")).to be_truthy
      end
    end

    after(:each) do
      @keyfile.unlink
    end
  end

  describe "#crl_file_valid?" do
    require "tempfile"

    before(:each) do
      @crlfile = Tempfile.new("crlfile")
    end

    context "When the crl file doesnt not exist" do
      it "returns false" do
        expect(instance.crl_file_valid?("/tmp/bad_filename")).to be_falsey
      end
    end

    context "When the crl file does exist, but does not contain a valid CRL" do
      it "returns false" do
        @crlfile.write("I_am_not_a_crl_I_am_a_free_man")
        @crlfile.close
        expect(instance.crl_file_valid?(@crlfile.path)).to be_falsey
      end
    end

    context "When the crl file does exist, and does contain a vaild CRL" do
      it "returns true" do
        @crlfile.write("-----BEGIN X509 CRL-----\nMIIBbjCB0QIBATAKBggqhkjOPQQDAjAOMQwwCgYDVQQDDANDQTIXDTE4MDgwMTE3\nMjg1NVoXDTE4MDgwOTE3Mjg1NVowNjA0AhUAx7y2YCouQlHvTignoijLUrwM6i8X\nDTE4MDgwMTE3Mjg1NVowDDAKBgNVHRUEAwoBAKBaMFgwCgYDVR0UBAMCAQQwSgYD\nVR0jBEMwQYAUCqE8XxFIFys0LTVPvsO1UtmrlyOhEqQQMA4xDDAKBgNVBAMMA0NB\nMoIVAPneTuAa1LzrK0wiZrxE8/1lSTp3MAoGCCqGSM49BAMCA4GLADCBhwJBct+Z\nZV3IZkPNevQv2S8lZ6kAMudN8R4QSzIQfM354Uk880RyQStP2S5Mb4gW3aFzwAy2\n/+rbx0bn2WmwoQv17I8CQgDtbvhf9chyPgMwAGCF7al04fve90fU1zRNH0zX1j9H\niDA2q1uBX+3TcTWcN+xgNimeRpvJFJ3uOB6w7jtwqGf1YQ==\n-----END X509 CRL-----\n")
        @crlfile.close
        expect(instance.crl_file_valid?(@crlfile.path)).to be_truthy
      end
    end

    after(:each) do
      @crlfile.unlink
    end
  end

  # Generators
  describe "#gen_dhparam" do
    context "When given an invalid key length" do
      it "Throws an ArgumentError" do
        expect do
          instance.gen_dhparam(2046, 2)
        end.to raise_error(ArgumentError)
      end
    end

    context "When given an invalid generator id" do
      it "Throws a TypeError" do
        expect do
          instance.gen_dhparam(2048, "bob")
        end.to raise_error(TypeError)
      end
    end

    context "When a proper key length and generator id are given" do
      it "Generates a dhparam object" do
        expect(instance.gen_dhparam(1024, 2)).to be_kind_of(OpenSSL::PKey::DH)
      end
    end
  end

  describe "#gen_rsa_priv_key" do
    context "When given an invalid key length" do
      it "Throws an ArgumentError" do
        expect do
          instance.gen_rsa_priv_key(4093)
        end.to raise_error(ArgumentError)
      end
    end

    context "When a proper key length is given" do
      it "Generates an RSA key object" do
        expect(instance.gen_rsa_priv_key(1024)).to be_kind_of(OpenSSL::PKey::RSA)
      end
    end
  end

  describe "#encrypt_rsa_key" do
    before(:all) do
      @rsa_key = OpenSSL::PKey::RSA.new(1024)
    end

    context "When given anything other than an RSA key object to encrypt" do
      it "Raises a TypeError" do
        expect do
          instance.encrypt_rsa_key("abcd", "efgh", "des3")
        end.to raise_error(TypeError)
      end
    end

    context "When given anything other than a string as the passphrase" do
      it "Raises a TypeError" do
        expect do
          instance.encrypt_rsa_key(@rsa_key, 1234, "des3")
        end.to raise_error(TypeError)
      end
    end

    context "When given anything other than a string as the cipher" do
      it "Raises a TypeError" do
        expect do
          instance.encrypt_rsa_key(@rsa_key, "1234", 1234)
        end.to raise_error(TypeError)
      end
    end

    context "When given an invalid cipher string" do
      it "Raises an ArgumentError" do
        expect do
          instance.encrypt_rsa_key(@rsa_key, "1234", "des3_bogus")
        end.to raise_error(ArgumentError)
      end
    end

    context "When given a valid RSA key and a valid passphrase string" do
      it "Generates a valid encrypted PEM" do
        @encrypted_key = instance.encrypt_rsa_key(@rsa_key, "oink", "des3")
        expect(@encrypted_key).to be_kind_of(String)
        expect(OpenSSL::PKey::RSA.new(@encrypted_key, "oink").private?).to be_truthy
      end
    end
  end

  describe "#gen_ec_priv_key" do
    context "When given an invalid curve" do
      it "Raises a TypeError" do
        expect do
          instance.gen_ec_priv_key(2048)
        end.to raise_error(TypeError)
      end

      it "Throws an ArgumentError" do
        expect do
          instance.gen_ec_priv_key("primeFromTheFuture")
        end.to raise_error(ArgumentError)
      end
    end

    context "When a proper curve is given" do
      it "Generates an ec key object" do
        expect(instance.gen_ec_priv_key("prime256v1")).to be_kind_of(OpenSSL::PKey::EC)
      end
    end
  end

  describe "#encrypt_ec_key" do
    before(:all) do
      @ec_key = OpenSSL::PKey::EC.generate("prime256v1")
    end

    context "When given anything other than an EC key object to encrypt" do
      it "Raises a TypeError" do
        expect do
          instance.encrypt_ec_key("abcd", "efgh", "des3")
        end.to raise_error(TypeError)
      end
    end

    context "When given anything other than a string as the passphrase" do
      it "Raises a TypeError" do
        expect do
          instance.encrypt_ec_key(@ec_key, 1234, "des3")
        end.to raise_error(TypeError)
      end
    end

    context "When given anything other than a string as the cipher" do
      it "Raises a TypeError" do
        expect do
          instance.encrypt_ec_key(@ec_key, "1234", 1234)
        end.to raise_error(TypeError)
      end
    end

    context "When given an invalid cipher string" do
      it "Raises an ArgumentError" do
        expect do
          instance.encrypt_ec_key(@ec_key, "1234", "des3_bogus")
        end.to raise_error(ArgumentError)
      end
    end

    context "When given a valid ec key and a valid passphrase string" do
      it "Generates a valid encrypted PEM" do
        @encrypted_key = instance.encrypt_ec_key(@ec_key, "oink", "des3")
        expect(@encrypted_key).to be_kind_of(String)
        expect(OpenSSL::PKey::EC.new(@encrypted_key, "oink").private?).to be_truthy
      end
    end
  end

  describe "#gen_x509_request" do
    before(:all) do
      @subject = OpenSSL::X509::Name.new [%w{CN x509request}]
      @ec_key = OpenSSL::PKey::EC.generate("prime256v1")
      @rsa_key = OpenSSL::PKey::RSA.new(2048)
    end

    context "When given anything other than an RSA/EC key object" do
      it "Raises a TypeError" do
        expect do
          instance.gen_x509_request(@subject, "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When given anything other than an X509 Name object" do
      it "Raises a TypeError" do
        expect do
          instance.gen_x509_request("abc", @key)
        end.to raise_error(TypeError)
      end
    end

    context "When given a valid EC key and a valid subject" do
      it "Generates a valid x509 request PEM" do
        @x509_request = instance.gen_x509_request(@subject, @ec_key)
        expect(@x509_request).to be_kind_of(OpenSSL::X509::Request)
        expect(OpenSSL::X509::Request.new(@x509_request).verify(@ec_key)).to be_truthy
      end
    end

    context "When given a valid RSA key and a valid subject" do
      it "Generates a valid x509 request PEM" do
        @x509_request = instance.gen_x509_request(@subject, @rsa_key)
        expect(@x509_request).to be_kind_of(OpenSSL::X509::Request)
        expect(OpenSSL::X509::Request.new(@x509_request).verify(@rsa_key)).to be_truthy
      end
    end
  end

  describe "#gen_x509_extensions" do
    context "When given anything other than an Ruby Hash object" do
      it "Raises a TypeError" do
        expect do
          instance.gen_x509_extensions("abc")
        end.to raise_error(TypeError)
      end
    end

    context "When a misformatted ruby Hash is given" do
      it "Raises a TypeError" do
        expect do
          instance.gen_x509_extensions("pouet" => "plop")
        end.to raise_error(TypeError)
      end

      it "Raises a ArgumentError" do
        expect do
          instance.gen_x509_extensions("pouet" => { "values" => [ "keyCertSign" ], "wrong_key" => true })
        end.to raise_error(ArgumentError)
      end

      it "Raises a TypeError" do
        expect do
          instance.gen_x509_extensions("keyUsage" => { "values" => "keyCertSign", "critical" => true })
        end.to raise_error(TypeError)
      end

      it "Raises a TypeError" do
        expect do
          instance.gen_x509_extensions("keyUsage" => { "values" => [ "keyCertSign" ], "critical" => "yes" })
        end.to raise_error(TypeError)
      end
    end

    context "When given a well formatted ruby Hash" do
      it "Generates a valid Array of X509 Extensions" do
        @x509_extension = instance.gen_x509_extensions("keyUsage" => { "values" => [ "keyCertSign" ], "critical" => true })
        expect(@x509_extension).to be_kind_of(Array)
        @x509_extension.each { |e| expect(e).to be_kind_of(OpenSSL::X509::Extension) }
      end
    end
  end

  describe "#gen_x509_cert" do
    before(:all) do
      @instance = Class.new { include Chef::Mixin::OpenSSLHelper }.new
      @rsa_key = OpenSSL::PKey::RSA.new(2048)
      @ec_key = OpenSSL::PKey::EC.generate("prime256v1")

      @rsa_request = @instance.gen_x509_request(OpenSSL::X509::Name.new([%w{CN RSACert}]), @rsa_key)
      @ec_request = @instance.gen_x509_request(OpenSSL::X509::Name.new([%w{CN ECCert}]), @ec_key)

      @x509_extension = @instance.gen_x509_extensions("keyUsage" => { "values" => [ "keyCertSign" ], "critical" => true })

      # Generating CA
      @ca_key = OpenSSL::PKey::RSA.new(2048)
      @ca_cert = OpenSSL::X509::Certificate.new
      @ca_cert.version = 2
      @ca_cert.serial = 1
      @ca_cert.subject = OpenSSL::X509::Name.new [%w{CN TestCA}]
      @ca_cert.issuer = @ca_cert.subject
      @ca_cert.public_key = @ca_key.public_key
      @ca_cert.not_before = Time.now
      @ca_cert.not_after = @ca_cert.not_before + 365 * 24 * 60 * 60
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = @ca_cert
      ef.issuer_certificate = @ca_cert
      @ca_cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
      @ca_cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
      @ca_cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
      @ca_cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
      @ca_cert.sign(@ca_key, OpenSSL::Digest.new("SHA256"))

      @info_with_issuer = { "validity" => 365, "issuer" => @ca_cert }
      @info_without_issuer = { "validity" => 365 }
    end

    context "When the request given is anything other then a Ruby OpenSSL::X509::Request" do
      it "Raises a TypeError" do
        expect do
          @instance.gen_x509_cert("abc", @x509_extension, @info_without_issuer, @rsa_key)
        end.to raise_error(TypeError)
      end
    end

    context "When the extension given is anything other then a Ruby Array" do
      it "Raises a TypeError" do
        expect do
          @instance.gen_x509_cert(@rsa_request, "abc", @info_without_issuer, @rsa_key)
        end.to raise_error(TypeError)
      end
    end

    context "When the info given is anything other then a Ruby Hash" do
      it "Raises a TypeError" do
        expect do
          @instance.gen_x509_cert(@rsa_request, @x509_extension, "abc", @rsa_key)
        end.to raise_error(TypeError)
      end
    end

    context "When the key given is anything other then a Ruby OpenSSL::Pkey::EC or OpenSSL::Pkey::RSA object" do
      it "Raises a TypeError" do
        expect do
          @instance.gen_x509_cert(@rsa_request, @x509_extension, @info_without_issuer, "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When given valid parameters to generate a self signed certificate" do
      it "Generates a valid x509 Certificate" do
        @x509_certificate = @instance.gen_x509_cert(@rsa_request, @x509_extension, @info_without_issuer, @rsa_key)
        expect(@x509_certificate).to be_kind_of(OpenSSL::X509::Certificate)
        expect(OpenSSL::X509::Certificate.new(@x509_certificate).verify(@rsa_key)).to be_truthy
      end
    end

    context "When given valid parameters to generate a CA signed certificate" do
      it "Generates a valid x509 Certificate" do
        @x509_certificate = @instance.gen_x509_cert(@ec_request, @x509_extension, @info_with_issuer, @ca_key)
        expect(@x509_certificate).to be_kind_of(OpenSSL::X509::Certificate)
        expect(OpenSSL::X509::Certificate.new(@x509_certificate).verify(@ca_key)).to be_truthy
      end
    end
  end

  describe "#get_next_crl_number" do
    before(:all) do
      @crl = OpenSSL::X509::CRL. new "-----BEGIN X509 CRL-----\nMIIBbTCB0QIBATAKBggqhkjOPQQDAjAOMQwwCgYDVQQDDANDQTIXDTE4MDgwMjA5\nMzc0OFoXDTE4MDgxMDA5Mzc0OFowNjA0AhUAx7y2YCouQlHvTignoijLUrwM6i8X\nDTE4MDgwMjA5Mzc0OFowDDAKBgNVHRUEAwoBAKBaMFgwCgYDVR0UBAMCAQQwSgYD\nVR0jBEMwQYAUxRlLNQUIOeWVaYm6HS0qFIbNCs2hEqQQMA4xDDAKBgNVBAMMA0NB\nMoIVAN1nyw8cj7IbhRLBu2CfS9Q8ILmDMAoGCCqGSM49BAMCA4GKADCBhgJBNR3o\njo/PzFwFGJKxIMa09pU+jprLG2CWehpZ4tGDjwiDCfZBztkg3H15eu+hyWmDp0U9\neAP5iJHVb12/3KZP0YUCQSgmaoLF68+Gh7ha+hcDjwFhzqdgmh/UlGPaxFBJ1BiQ\nQq9uBn0IT4o7v1Tv2WRZNDk7oiuRaZG+R9IodiZPsGKv\n-----END X509 CRL-----\n"
    end

    context "When the CRL given is anything other then a Ruby OpenSSL::X509::CRL object" do
      it "Raises a TypeError" do
        expect do
          instance.get_next_crl_number("abc")
        end.to raise_error(TypeError)
      end
    end

    context "When given valid parameter to get the next crlNumber" do
      it "Get 5" do
        @next_crl = instance.get_next_crl_number(@crl)
        expect(@next_crl).to be_kind_of(Integer)
        expect(@next_crl == 5).to be_truthy
      end
    end
  end

  describe "#serial_revoked?" do
    before(:all) do
      @crl = OpenSSL::X509::CRL. new "-----BEGIN X509 CRL-----\nMIIBbTCB0QIBATAKBggqhkjOPQQDAjAOMQwwCgYDVQQDDANDQTIXDTE4MDgwMjA5\nMzc0OFoXDTE4MDgxMDA5Mzc0OFowNjA0AhUAx7y2YCouQlHvTignoijLUrwM6i8X\nDTE4MDgwMjA5Mzc0OFowDDAKBgNVHRUEAwoBAKBaMFgwCgYDVR0UBAMCAQQwSgYD\nVR0jBEMwQYAUxRlLNQUIOeWVaYm6HS0qFIbNCs2hEqQQMA4xDDAKBgNVBAMMA0NB\nMoIVAN1nyw8cj7IbhRLBu2CfS9Q8ILmDMAoGCCqGSM49BAMCA4GKADCBhgJBNR3o\njo/PzFwFGJKxIMa09pU+jprLG2CWehpZ4tGDjwiDCfZBztkg3H15eu+hyWmDp0U9\neAP5iJHVb12/3KZP0YUCQSgmaoLF68+Gh7ha+hcDjwFhzqdgmh/UlGPaxFBJ1BiQ\nQq9uBn0IT4o7v1Tv2WRZNDk7oiuRaZG+R9IodiZPsGKv\n-----END X509 CRL-----\n"
    end

    context "When the CRL given is anything other then a Ruby OpenSSL::X509::CRL object" do
      it "Raises a TypeError" do
        expect do
          instance.serial_revoked?("abc", "C7BCB6602A2E4251EF4E2827A228CB52BC0CEA2F")
        end.to raise_error(TypeError)
      end
    end

    context "When the serial given is anything other then a Ruby String or Integer object" do
      it "Raises a TypeError" do
        expect do
          instance.serial_revoked?(@crl, [])
        end.to raise_error(TypeError)
      end
    end

    context "When given valid parameters to know if the serial is revoked" do
      it "get true" do
        @serial_revoked = instance.serial_revoked?(@crl, "C7BCB6602A2E4251EF4E2827A228CB52BC0CEA2F")
        expect(@serial_revoked).to be_kind_of(TrueClass)
      end
    end
  end

  describe "#gen_x509_crl" do
    before(:all) do
      # Generating CA

      @ca_key = OpenSSL::PKey::RSA.new(2048)
      @ca_cert = OpenSSL::X509::Certificate.new
      @ca_cert.version = 2
      @ca_cert.serial = 1
      @ca_cert.subject = OpenSSL::X509::Name.new [%w{CN TestCA}]
      @ca_cert.issuer = @ca_cert.subject
      @ca_cert.public_key = @ca_key.public_key
      @ca_cert.not_before = Time.now
      @ca_cert.not_after = @ca_cert.not_before + 365 * 24 * 60 * 60
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = @ca_cert
      ef.issuer_certificate = @ca_cert
      @ca_cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
      @ca_cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
      @ca_cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
      @ca_cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
      @ca_cert.sign(@ca_key, OpenSSL::Digest.new("SHA256"))

      @info = { "validity" => 8, "issuer" => @ca_cert }
    end

    context "When the CA private key given is anything other then a Ruby OpenSSL::PKey::EC object or a OpenSSL::PKey::RSA object" do
      it "Raises a TypeError" do
        expect do
          instance.gen_x509_crl("abc", @info)
        end.to raise_error(TypeError)
      end
    end

    context "When the info given is anything other then a Ruby Hash" do
      it "Raises a TypeError" do
        expect do
          instance.gen_x509_crl(@ca_key, "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When a misformatted info Ruby Hash is given" do
      it "Raises a ArgumentError" do
        expect do
          instance.gen_x509_crl(@ca_key, "abc" => "def", "validity" => 8)
        end.to raise_error(ArgumentError)
      end

      it "Raises a TypeError" do
        expect do
          instance.gen_x509_crl(@ca_key, "issuer" => "abc", "validity" => 8)
        end.to raise_error(TypeError)
      end

      it "Raises a TypeError" do
        expect do
          instance.gen_x509_crl(@ca_key, "issuer" => @ca_cert, "validity" => "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When given valid parameters to generate a CRL" do
      it "Generates a valid x509 CRL" do
        @x509_crl = instance.gen_x509_crl(@ca_key, @info)
        expect(@x509_crl).to be_kind_of(OpenSSL::X509::CRL)
        expect(OpenSSL::X509::CRL.new(@x509_crl).verify(@ca_key)).to be_truthy
      end
    end
  end

  describe "#renew_x509_crl" do
    before(:all) do
      # Generating CA
      @instance = Class.new { include Chef::Mixin::OpenSSLHelper }.new
      @ca_key = OpenSSL::PKey::RSA.new(2048)
      @ca_cert = OpenSSL::X509::Certificate.new
      @ca_cert.version = 2
      @ca_cert.serial = 1
      @ca_cert.subject = OpenSSL::X509::Name.new [%w{CN TestCA}]
      @ca_cert.issuer = @ca_cert.subject
      @ca_cert.public_key = @ca_key.public_key
      @ca_cert.not_before = Time.now
      @ca_cert.not_after = @ca_cert.not_before + 365 * 24 * 60 * 60
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = @ca_cert
      ef.issuer_certificate = @ca_cert
      @ca_cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
      @ca_cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
      @ca_cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
      @ca_cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
      @ca_cert.sign(@ca_key, OpenSSL::Digest.new("SHA256"))

      @info = { "validity" => 8, "issuer" => @ca_cert }

      @crl = @instance.gen_x509_crl(@ca_key, @info)
    end

    context "When the CRL given is anything other then a Ruby OpenSSL::X509::CRL object" do
      it "Raises a TypeError" do
        expect do
          instance.renew_x509_crl("abc", @ca_key, @info)
        end.to raise_error(TypeError)
      end
    end

    context "When the CA private key given is anything other then a Ruby OpenSSL::PKey::EC object or a OpenSSL::PKey::RSA object" do
      it "Raises a TypeError" do
        expect do
          instance.renew_x509_crl(@crl, "abc", @info)
        end.to raise_error(TypeError)
      end
    end

    context "When the info given is anything other then a Ruby Hash" do
      it "Raises a TypeError" do
        expect do
          instance.renew_x509_crl(@crl, @ca_key, "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When a misformatted info Ruby Hash is given" do
      it "Raises a ArgumentError" do
        expect do
          instance.renew_x509_crl(@crl, @ca_key, "abc" => "def", "validity" => 8)
        end.to raise_error(ArgumentError)
      end

      it "Raises a TypeError" do
        expect do
          instance.renew_x509_crl(@crl, @ca_key, "issuer" => "abc", "validity" => 8)
        end.to raise_error(TypeError)
      end

      it "Raises a TypeError" do
        expect do
          instance.renew_x509_crl(@crl, @ca_key, "issuer" => @ca_cert, "validity" => "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When given valid parameters to renew a CRL" do
      it "Renew a valid x509 CRL" do
        @renewed_crl = instance.renew_x509_crl(@crl, @ca_key, @info)
        expect(@renewed_crl).to be_kind_of(OpenSSL::X509::CRL)
        expect(OpenSSL::X509::CRL.new(@renewed_crl).verify(@ca_key)).to be_truthy
      end
    end
  end

  describe "#revoke_x509_crl" do
    before(:all) do
      # Generating CA

      @instance = Class.new { include Chef::Mixin::OpenSSLHelper }.new
      @ca_key = OpenSSL::PKey::RSA.new(2048)
      @ca_cert = OpenSSL::X509::Certificate.new
      @ca_cert.version = 2
      @ca_cert.serial = 1
      @ca_cert.subject = OpenSSL::X509::Name.new [%w{CN TestCA}]
      @ca_cert.issuer = @ca_cert.subject
      @ca_cert.public_key = @ca_key.public_key
      @ca_cert.not_before = Time.now
      @ca_cert.not_after = @ca_cert.not_before + 365 * 24 * 60 * 60
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = @ca_cert
      ef.issuer_certificate = @ca_cert
      @ca_cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
      @ca_cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
      @ca_cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
      @ca_cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
      @ca_cert.sign(@ca_key, OpenSSL::Digest.new("SHA256"))

      @info = { "validity" => 8, "issuer" => @ca_cert }

      @crl = @instance.gen_x509_crl(@ca_key, @info)
      @revoke_info = { "serial" => 1, "reason" => 0 }
    end

    context "When the revoke_info given is anything other then a Ruby Hash" do
      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl("abc", @crl, @ca_key, @info)
        end.to raise_error(TypeError)
      end
    end

    context "When the CRL given is anything other then a Ruby OpenSSL::X509::CRL object" do
      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl(@revoke_info, "abc", @ca_key, @info)
        end.to raise_error(TypeError)
      end
    end

    context "When the CA private key given is anything other then a Ruby OpenSSL::PKey::EC object or a OpenSSL::PKey::RSA object" do
      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl(@revoke_info, @crl, "abc", @info)
        end.to raise_error(TypeError)
      end
    end

    context "When the info given is anything other then a Ruby Hash" do
      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl(@revoke_info, @crl, @ca_key, "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When a misformatted revoke_info Ruby Hash is given" do
      it "Raises a ArgumentError" do
        expect do
          instance.revoke_x509_crl({ "abc" => "def", "ghi" => "jkl" }, @crl, @ca_key, @info)
        end.to raise_error(ArgumentError)
      end

      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl({ "serial" => [], "reason" => 0 }, @crl, @ca_key, @info)
        end.to raise_error(TypeError)
      end

      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl({ "serial" => 1, "reason" => "abc" }, @crl, @ca_key, @info)
        end.to raise_error(TypeError)
      end
    end

    context "When a misformatted info Ruby Hash is given" do
      it "Raises a ArgumentError" do
        expect do
          instance.revoke_x509_crl(@revoke_info, @crl, @ca_key, "abc" => "def", "validity" => 8)
        end.to raise_error(ArgumentError)
      end

      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl(@revoke_info, @crl, @ca_key, "issuer" => "abc", "validity" => 8)
        end.to raise_error(TypeError)
      end

      it "Raises a TypeError" do
        expect do
          instance.revoke_x509_crl(@revoke_info, @crl, @ca_key, "issuer" => @ca_cert, "validity" => "abc")
        end.to raise_error(TypeError)
      end
    end

    context "When given valid parameters to revoke a Serial in a CRL" do
      it "Revoke a Serial in a CRL" do
        @crl_with_revoked_serial = instance.revoke_x509_crl(@revoke_info, @crl, @ca_key, @info)
        expect(@crl_with_revoked_serial).to be_kind_of(OpenSSL::X509::CRL)
        expect(OpenSSL::X509::CRL.new(@crl_with_revoked_serial).verify(@ca_key)).to be_truthy
        expect(instance.serial_revoked?(@crl_with_revoked_serial, 1)).to be_truthy
      end
    end
  end

  describe "#cert_need_renewall?" do
    require "tempfile"

    before(:each) do
      @certfile = Tempfile.new("certfile")
    end

    context "When the cert file doesn't exist" do
      it "returns true" do
        expect(instance.cert_need_renewall?("/tmp/bad_filename", 3650)).to be_truthy
      end
    end

    context "When the cert file does exist, but does not contain a valid Certificate" do
      it "returns true" do
        @certfile.write("I_am_not_a_cert_I_am_a_free_man")
        @certfile.close
        expect(instance.cert_need_renewall?(@certfile.path, 3650)).to be_truthy
      end
    end

    context "When the cert file does exist, and does not contain a soon to expire certificate" do
      it "returns false" do
        @certfile.write("-----BEGIN CERTIFICATE-----\nMIIDODCCAiCgAwIBAgIVAPCkjE+wlZ1PgXwgvFgXKzhSpUkvMA0GCSqGSIb3DQEB\nCwUAMA0xCzAJBgNVBAMMAkNBMB4XDTE5MTIyNTEyNTY1NVoXDTI5MTIyMjEyNTY1\nNVowDTELMAkGA1UEAwwCQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB\nAQC9bDWs5akf85UEMj8kry4DYNuAnaL4GnMs6XukQtp3dso+FgbKprgVogyepnet\nE+GlQq32u/n4y8K228kB6NoCn+c/yP+4QlKUBt0xSzQbSUuAE/5xZoKi/kH1ZsQ/\nuKXN/tIHagApEUGn5zqc8WBvWPliRAqiklwj8WtSw1WRa5eCdaVtln3wKuvPnYR5\n/V4YBHyHNhtlfXJBMtEaXm1rRzJGun+FdcrsCfcIFXp8lWobF+EVP8fRwqFTEtT6\nRXv6RT8sHy53a0KNTm8qnbacfr1MofgUuhzLjOrbIVvXpnRLeOkv8XW5rSH+zgsC\nZFK3bJ3j6UVbFQV4jXwlAWVrAgMBAAGjgY4wgYswDgYDVR0PAQH/BAQDAgGmMA8G\nA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFK4S2PNu6bpjxkJxedNaxfCrwtD4MEkG\nA1UdIwRCMECAFK4S2PNu6bpjxkJxedNaxfCrwtD4oRGkDzANMQswCQYDVQQDDAJD\nQYIVAPCkjE+wlZ1PgXwgvFgXKzhSpUkvMA0GCSqGSIb3DQEBCwUAA4IBAQBGk+u3\n9N3PLWNOwYrqK7fD4yceWnz4UsV9uN1IU5PQTgYBaGyAZvU+VJluZZeDj7QjwbUW\ngISclvW/pSWpUVW3O0sfAM97u+5UMYHz4W5Bgq8CtdOKHgdZHKhzBePhmou11zO0\nZ6uQ7bkh0/REqKO7TFKaMMnakEhFXoDrS1EiB4W69KVXyrBVzVm5LK7uvOAQAeMp\nnEk3Oz+5pmKjSCf1cEd2jzAgDbaVrIvxICPgXAlNrKukmRW/0UHqDDVBfF7PioD2\nptlQFxWIkih6s/clwhsBFBwV1yyCirYfjhzmKPPLZUmx10okudLzaKrRbkPxrzbC\nmKEZoV+Nz2CNrGm5\n-----END CERTIFICATE-----\n")
        @certfile.close
        expect(instance.cert_need_renewall?(@certfile.path, 5)).to be_falsey
      end
    end

    context "When the cert file does exist, and does contain a soon to expire certificate" do
      it "returns true" do
        @certfile.write("-----BEGIN CERTIFICATE-----\nMIIDODCCAiCgAwIBAgIVAPCkjE+wlZ1PgXwgvFgXKzhSpUkvMA0GCSqGSIb3DQEB\nCwUAMA0xCzAJBgNVBAMMAkNBMB4XDTE5MTIyNTEyNTY1NVoXDTI5MTIyMjEyNTY1\nNVowDTELMAkGA1UEAwwCQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB\nAQC9bDWs5akf85UEMj8kry4DYNuAnaL4GnMs6XukQtp3dso+FgbKprgVogyepnet\nE+GlQq32u/n4y8K228kB6NoCn+c/yP+4QlKUBt0xSzQbSUuAE/5xZoKi/kH1ZsQ/\nuKXN/tIHagApEUGn5zqc8WBvWPliRAqiklwj8WtSw1WRa5eCdaVtln3wKuvPnYR5\n/V4YBHyHNhtlfXJBMtEaXm1rRzJGun+FdcrsCfcIFXp8lWobF+EVP8fRwqFTEtT6\nRXv6RT8sHy53a0KNTm8qnbacfr1MofgUuhzLjOrbIVvXpnRLeOkv8XW5rSH+zgsC\nZFK3bJ3j6UVbFQV4jXwlAWVrAgMBAAGjgY4wgYswDgYDVR0PAQH/BAQDAgGmMA8G\nA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFK4S2PNu6bpjxkJxedNaxfCrwtD4MEkG\nA1UdIwRCMECAFK4S2PNu6bpjxkJxedNaxfCrwtD4oRGkDzANMQswCQYDVQQDDAJD\nQYIVAPCkjE+wlZ1PgXwgvFgXKzhSpUkvMA0GCSqGSIb3DQEBCwUAA4IBAQBGk+u3\n9N3PLWNOwYrqK7fD4yceWnz4UsV9uN1IU5PQTgYBaGyAZvU+VJluZZeDj7QjwbUW\ngISclvW/pSWpUVW3O0sfAM97u+5UMYHz4W5Bgq8CtdOKHgdZHKhzBePhmou11zO0\nZ6uQ7bkh0/REqKO7TFKaMMnakEhFXoDrS1EiB4W69KVXyrBVzVm5LK7uvOAQAeMp\nnEk3Oz+5pmKjSCf1cEd2jzAgDbaVrIvxICPgXAlNrKukmRW/0UHqDDVBfF7PioD2\nptlQFxWIkih6s/clwhsBFBwV1yyCirYfjhzmKPPLZUmx10okudLzaKrRbkPxrzbC\nmKEZoV+Nz2CNrGm5\n-----END CERTIFICATE-----\n")
        @certfile.close
        expect(instance.cert_need_renewall?(@certfile.path, 3650)).to be_truthy
      end
    end

    after(:each) do
      @certfile.unlink
    end
  end
end
