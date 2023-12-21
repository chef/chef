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
autoload :OpenSSL, "openssl"

class Chef
  module Mixin
    # various helpers for use with openssl. Currently used by the openssl_* resources
    module OpenSSLHelper
      # determine the key filename from the cert filename
      # @param [String] cert_filename the path to the certfile
      # @return [String] the path to the keyfile
      def get_key_filename(cert_filename)
        cert_file_path, cert_filename = ::File.split(cert_filename)
        cert_filename = ::File.basename(cert_filename, ::File.extname(cert_filename))
        cert_file_path + ::File::SEPARATOR + cert_filename + ".key"
      end

      # is the key length a valid key length
      # @param [Integer] number
      # @return [Boolean] is length valid
      def key_length_valid?(number)
        number >= 1024 && ( number & (number - 1) == 0 )
      end

      # validate a dhparam file from path
      # @param [String] dhparam_pem_path the path to the pem file
      # @return [Boolean] is the key valid
      def dhparam_pem_valid?(dhparam_pem_path)
        # Check if the dhparam.pem file exists
        # Verify the dhparam.pem file contains a key
        return false unless ::File.exist?(dhparam_pem_path)

        dhparam = ::OpenSSL::PKey::DH.new File.read(dhparam_pem_path)
        dhparam.params_ok?
      end

      # given either a key file path or key file content see if it's actually
      # a private key
      # @param [String] key_file the path to the keyfile or the key contents
      # @param [String] key_password optional password to the keyfile
      # @return [Boolean] is the key valid?
      def priv_key_file_valid?(key_file, key_password = nil)
        # if the file exists try to read the content
        # if not assume we were passed the key and set the string to the content
        key_content = ::File.exist?(key_file) ? File.read(key_file) : key_file

        begin
          key = ::OpenSSL::PKey.read key_content, key_password
        rescue ::OpenSSL::PKey::PKeyError, ArgumentError
          return false
        end

        if key.is_a?(::OpenSSL::PKey::EC)
          key.private_key?
        else
          key.private?
        end
      end

      # given a crl file path see if it's actually a crl
      # @param [String] crl_file the path to the crlfile
      # @return [Boolean] is the key valid?
      def crl_file_valid?(crl_file)
        begin
          ::OpenSSL::X509::CRL.new ::File.read(crl_file)
        rescue ::OpenSSL::X509::CRLError, Errno::ENOENT
          return false
        end
        true
      end

      # check is a serial given is revoked in a crl given
      # @param [OpenSSL::X509::CRL] crl X509 CRL to check
      # @param [String, Integer] serial X509 Certificate Serial Number
      # @return [true, false]
      def serial_revoked?(crl, serial)
        raise TypeError, "crl must be a Ruby OpenSSL::X509::CRL object" unless crl.is_a?(::OpenSSL::X509::CRL)
        raise TypeError, "serial must be a Ruby String or Integer object" unless serial.is_a?(String) || serial.is_a?(Integer)

        serial_to_verify = if serial.is_a?(String)
                             serial.to_i(16)
                           else
                             serial
                           end
        status = false
        crl.revoked.each do |revoked|
          status = true if revoked.serial == serial_to_verify
        end
        status
      end

      # generate a dhparam file
      # @param [String] key_length the length of the key
      # @param [Integer] generator the dhparam generator to use
      # @return [OpenSSL::PKey::DH]
      def gen_dhparam(key_length, generator)
        raise ArgumentError, "Key length must be a power of 2 greater than or equal to 1024" unless key_length_valid?(key_length)
        raise TypeError, "Generator must be an integer" unless generator.is_a?(Integer)

        ::OpenSSL::PKey::DH.new(key_length, generator)
      end

      # generate an RSA private key given key length
      # @param [Integer] key_length the key length of the private key
      # @return [OpenSSL::PKey::DH]
      def gen_rsa_priv_key(key_length)
        raise ArgumentError, "Key length must be a power of 2 greater than or equal to 1024" unless key_length_valid?(key_length)

        ::OpenSSL::PKey::RSA.new(key_length)
      end

      # generate pem format of the public key given a private key
      # @param [String] priv_key either the contents of the private key or the path to the file
      # @param [String] priv_key_password optional password for the private key
      # @return [String] pem format of the public key
      def gen_rsa_pub_key(priv_key, priv_key_password = nil)
        # if the file exists try to read the content
        # if not assume we were passed the key and set the string to the content
        key_content = ::File.exist?(priv_key) ? File.read(priv_key) : priv_key
        key = ::OpenSSL::PKey::RSA.new key_content, priv_key_password
        key.public_key.to_pem
      end

      # generate a pem file given a cipher, key, an optional key_password
      # @param [OpenSSL::PKey::RSA] rsa_key the private key object
      # @param [String] key_password the password for the private key
      # @param [String] key_cipher the cipher to use
      # @return [String] pem contents
      def encrypt_rsa_key(rsa_key, key_password, key_cipher)
        raise TypeError, "rsa_key must be a Ruby OpenSSL::PKey::RSA object" unless rsa_key.is_a?(::OpenSSL::PKey::RSA)
        raise TypeError, "key_password must be a string" unless key_password.is_a?(String)
        raise TypeError, "key_cipher must be a string" unless key_cipher.is_a?(String)
        raise ArgumentError, "Specified key_cipher is not available on this system" unless ::OpenSSL::Cipher.ciphers.include?(key_cipher)

        cipher = ::OpenSSL::Cipher.new(key_cipher)
        rsa_key.to_pem(cipher, key_password)
      end

      # generate an ec private key given curve type
      # @param [String] curve the kind of curve to use
      # @return [OpenSSL::PKey::DH]
      def gen_ec_priv_key(curve)
        raise TypeError, "curve must be a string" unless curve.is_a?(String)
        raise ArgumentError, "Specified curve is not available on this system" unless %w{prime256v1 secp384r1 secp521r1}.include?(curve)

        ::OpenSSL::PKey::EC.generate(curve)
      end

      # generate pem format of the public key given a private key
      # @param [String] priv_key either the contents of the private key or the path to the file
      # @param [String] priv_key_password optional password for the private key
      # @return [String] pem format of the public key
      def gen_ec_pub_key(priv_key, priv_key_password = nil)
        # if the file exists try to read the content
        # if not assume we were passed the key and set the string to the content
        key_content = ::File.exist?(priv_key) ? File.read(priv_key) : priv_key
        key = ::OpenSSL::PKey::EC.new key_content, priv_key_password

        # Get curve type (prime256v1...)
        group = ::OpenSSL::PKey::EC::Group.new(key.group.curve_name)
        # Get Generator point & public point (priv * generator)
        generator = group.generator
        pub_point = generator.mul(key.private_key)
        key.public_key = pub_point

        # Public Key in pem
        public_key = ::OpenSSL::PKey::EC.new
        public_key.group = group
        public_key.public_key = pub_point
        public_key.to_pem
      end

      # generate a pem file given a cipher, key, an optional key_password
      # @param [OpenSSL::PKey::EC] ec_key the private key object
      # @param [String] key_password the password for the private key
      # @param [String] key_cipher the cipher to use
      # @return [String] pem contents
      def encrypt_ec_key(ec_key, key_password, key_cipher)
        raise TypeError, "ec_key must be a Ruby OpenSSL::PKey::EC object" unless ec_key.is_a?(::OpenSSL::PKey::EC)
        raise TypeError, "key_password must be a string" unless key_password.is_a?(String)
        raise TypeError, "key_cipher must be a string" unless key_cipher.is_a?(String)
        raise ArgumentError, "Specified key_cipher is not available on this system" unless ::OpenSSL::Cipher.ciphers.include?(key_cipher)

        cipher = ::OpenSSL::Cipher.new(key_cipher)
        ec_key.to_pem(cipher, key_password)
      end

      # generate a csr pem file given a subject and a private key
      # @param [OpenSSL::X509::Name] subject the x509 subject object
      # @param [OpenSSL::PKey::EC, OpenSSL::PKey::RSA] key the private key object
      # @return [OpenSSL::X509::Request]
      def gen_x509_request(subject, key)
        raise TypeError, "subject must be a Ruby OpenSSL::X509::Name object" unless subject.is_a?(::OpenSSL::X509::Name)
        raise TypeError, "key must be a Ruby OpenSSL::PKey::EC or a Ruby OpenSSL::PKey::RSA object" unless key.is_a?(::OpenSSL::PKey::EC) || key.is_a?(::OpenSSL::PKey::RSA)

        request = ::OpenSSL::X509::Request.new
        request.version = 0
        request.subject = subject
        request.public_key = key

        # Chef 12 backward compatibility
        ::OpenSSL::PKey::EC.send(:alias_method, :private?, :private_key?)

        request.sign(key, ::OpenSSL::Digest.new("SHA256"))
        request
      end

      # generate an array of X509 Extensions given a hash of extensions
      # @param [Hash] extensions hash of extensions
      # @return [Array]
      def gen_x509_extensions(extensions)
        raise TypeError, "extensions must be a Ruby Hash object" unless extensions.is_a?(Hash)

        exts = []
        extensions.each do |ext_name, ext_prop|
          raise TypeError, "#{ext_name} must contain a Ruby Hash" unless ext_prop.is_a?(Hash)
          raise ArgumentError, "keys in #{ext_name} must be 'values' and 'critical'" unless ext_prop.key?("values") && ext_prop.key?("critical")
          raise TypeError, "the key 'values' must contain a Ruby Arrays" unless ext_prop["values"].is_a?(Array)
          raise TypeError, "the key 'critical' must be a Ruby Boolean true/false" unless ext_prop["critical"].is_a?(TrueClass) || ext_prop["critical"].is_a?(FalseClass)

          exts << ::OpenSSL::X509::ExtensionFactory.new.create_extension(ext_name, ext_prop["values"].join(","), ext_prop["critical"])
        end
        exts
      end

      # generate a random Serial
      # @return [Integer]
      def gen_serial
        ::OpenSSL::BN.generate_prime(160)
      end

      # generate a Certificate given a X509 request
      # @param [OpenSSL::X509::Request] request X509 Certificate Request
      # @param [Array] extension Array of X509 Certificate Extension
      # @param [Hash] info issuer & validity
      # @param [OpenSSL::PKey::EC, OpenSSL::PKey::RSA] key private key to sign with
      # @return [OpenSSL::X509::Certificate]
      def gen_x509_cert(request, extension, info, key)
        raise TypeError, "request must be a Ruby OpenSSL::X509::Request" unless request.is_a?(::OpenSSL::X509::Request)
        raise TypeError, "extension must be a Ruby Array" unless extension.is_a?(Array)
        raise TypeError, "info must be a Ruby Hash" unless info.is_a?(Hash)
        raise TypeError, "key must be a Ruby OpenSSL::PKey::EC object or a Ruby OpenSSL::PKey::RSA object" unless key.is_a?(::OpenSSL::PKey::EC) || key.is_a?(::OpenSSL::PKey::RSA)

        raise ArgumentError, "info must contain a validity" unless info.key?("validity")
        raise TypeError, "info['validity'] must be a Ruby Integer object" unless info["validity"].is_a?(Integer)

        cert = ::OpenSSL::X509::Certificate.new
        ef = ::OpenSSL::X509::ExtensionFactory.new

        cert.serial = gen_serial
        cert.version = 2
        cert.subject = request.subject
        cert.public_key = request.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + info["validity"] * 24 * 60 * 60

        if info["issuer"].nil?
          cert.issuer = request.subject
          ef.issuer_certificate = cert
          extension << ef.create_extension("basicConstraints", "CA:TRUE", true)
        else
          raise TypeError, "info['issuer'] must be a Ruby OpenSSL::X509::Certificate object" unless info["issuer"].is_a?(::OpenSSL::X509::Certificate)

          cert.issuer = info["issuer"].subject
          ef.issuer_certificate = info["issuer"]
        end
        ef.subject_certificate = cert
        if openssl_config = __openssl_config
          ef.config = openssl_config
        end

        cert.extensions = extension
        cert.add_extension ef.create_extension("subjectKeyIdentifier", "hash")
        cert.add_extension ef.create_extension("authorityKeyIdentifier",
          "keyid:always,issuer:always")

        cert.sign(key, ::OpenSSL::Digest.new("SHA256"))
        cert
      end

      # generate a X509 CRL given a CA
      # @param [OpenSSL::PKey::EC, OpenSSL::PKey::RSA] ca_private_key private key from the CA
      # @param [Hash] info issuer & validity
      # @return [OpenSSL::X509::CRL]
      def gen_x509_crl(ca_private_key, info)
        raise TypeError, "ca_private_key must be a Ruby OpenSSL::PKey::EC object or a Ruby OpenSSL::PKey::RSA object" unless ca_private_key.is_a?(::OpenSSL::PKey::EC) || ca_private_key.is_a?(::OpenSSL::PKey::RSA)
        raise TypeError, "info must be a Ruby Hash" unless info.is_a?(Hash)

        raise ArgumentError, "info must contain a issuer and a validity" unless info.key?("issuer") && info.key?("validity")
        raise TypeError, "info['issuer'] must be a Ruby OpenSSL::X509::Certificate object" unless info["issuer"].is_a?(::OpenSSL::X509::Certificate)
        raise TypeError, "info['validity'] must be a Ruby Integer object" unless info["validity"].is_a?(Integer)

        crl = ::OpenSSL::X509::CRL.new
        ef = ::OpenSSL::X509::ExtensionFactory.new

        crl.version = 1
        crl.issuer = info["issuer"].subject
        crl.last_update = Time.now
        crl.next_update = Time.now + 3600 * 24 * info["validity"]

        if openssl_config = __openssl_config
          ef.config = openssl_config
        end
        ef.issuer_certificate = info["issuer"]

        crl.add_extension ::OpenSSL::X509::Extension.new("crlNumber", ::OpenSSL::ASN1::Integer(1))
        crl.add_extension ef.create_extension("authorityKeyIdentifier",
          "keyid:always,issuer:always")
        crl.sign(ca_private_key, ::OpenSSL::Digest.new("SHA256"))
        crl
      end

      # generate the next CRL number available for a X509 CRL given
      # @param [OpenSSL::X509::CRL] crl x509 CRL
      # @return [Integer]
      def get_next_crl_number(crl)
        raise TypeError, "crl must be a Ruby OpenSSL::X509::CRL object" unless crl.is_a?(::OpenSSL::X509::CRL)

        crlnum = 1
        crl.extensions.each do |e|
          crlnum = e.value if e.oid == "crlNumber"
        end
        crlnum.to_i + 1
      end

      # add a serial given in the crl given
      # @param [Hash] revoke_info serial to revoke & revocation reason
      # @param [OpenSSL::X509::CRL] crl X509 CRL
      # @param [OpenSSL::PKey::EC, OpenSSL::PKey::RSA] ca_private_key private key from the CA
      # @param [Hash] info issuer & validity
      # @return [OpenSSL::X509::CRL]
      def revoke_x509_crl(revoke_info, crl, ca_private_key, info)
        raise TypeError, "revoke_info must be a Ruby Hash object" unless revoke_info.is_a?(Hash)
        raise TypeError, "crl must be a Ruby OpenSSL::X509::CRL object" unless crl.is_a?(::OpenSSL::X509::CRL)
        raise TypeError, "ca_private_key must be a Ruby OpenSSL::PKey::EC object or a Ruby OpenSSL::PKey::RSA object" unless ca_private_key.is_a?(::OpenSSL::PKey::EC) || ca_private_key.is_a?(::OpenSSL::PKey::RSA)
        raise TypeError, "info must be a Ruby Hash" unless info.is_a?(Hash)

        raise ArgumentError, "revoke_info must contain a serial and a reason" unless revoke_info.key?("serial") && revoke_info.key?("reason")
        raise TypeError, "revoke_info['serial'] must be a Ruby String or Integer object" unless revoke_info["serial"].is_a?(String) || revoke_info["serial"].is_a?(Integer)
        raise TypeError, "revoke_info['reason'] must be a Ruby Integer object" unless revoke_info["reason"].is_a?(Integer)

        raise ArgumentError, "info must contain a issuer and a validity" unless info.key?("issuer") && info.key?("validity")
        raise TypeError, "info['issuer'] must be a Ruby OpenSSL::X509::Certificate object" unless info["issuer"].is_a?(::OpenSSL::X509::Certificate)
        raise TypeError, "info['validity'] must be a Ruby Integer object" unless info["validity"].is_a?(Integer)

        revoked = ::OpenSSL::X509::Revoked.new
        revoked.serial = if revoke_info["serial"].is_a?(String)
                           revoke_info["serial"].to_i(16)
                         else
                           revoke_info["serial"]
                         end
        revoked.time = Time.now

        ext = ::OpenSSL::X509::Extension.new("CRLReason",
          ::OpenSSL::ASN1::Enumerated(revoke_info["reason"]))
        revoked.add_extension(ext)
        crl.add_revoked(revoked)

        renew_x509_crl(crl, ca_private_key, info)
      end

      # renew a X509 crl given
      # @param [OpenSSL::X509::CRL] crl CRL to renew
      # @param [OpenSSL::PKey::EC, OpenSSL::PKey::RSA] ca_private_key private key from the CA
      # @param [Hash] info issuer & validity
      # @return [OpenSSL::X509::CRL]
      def renew_x509_crl(crl, ca_private_key, info)
        raise TypeError, "crl must be a Ruby OpenSSL::X509::CRL object" unless crl.is_a?(::OpenSSL::X509::CRL)
        raise TypeError, "ca_private_key must be a Ruby OpenSSL::PKey::EC object or a Ruby OpenSSL::PKey::RSA object" unless ca_private_key.is_a?(::OpenSSL::PKey::EC) || ca_private_key.is_a?(::OpenSSL::PKey::RSA)
        raise TypeError, "info must be a Ruby Hash" unless info.is_a?(Hash)

        raise ArgumentError, "info must contain a issuer and a validity" unless info.key?("issuer") && info.key?("validity")
        raise TypeError, "info['issuer'] must be a Ruby OpenSSL::X509::Certificate object" unless info["issuer"].is_a?(::OpenSSL::X509::Certificate)
        raise TypeError, "info['validity'] must be a Ruby Integer object" unless info["validity"].is_a?(Integer)

        crl.last_update = Time.now
        crl.next_update = crl.last_update + 3600 * 24 * info["validity"]

        ef = ::OpenSSL::X509::ExtensionFactory.new
        if openssl_config = __openssl_config
          ef.config = openssl_config
        end
        ef.issuer_certificate = info["issuer"]

        crl.extensions = [ ::OpenSSL::X509::Extension.new("crlNumber",
          ::OpenSSL::ASN1::Integer(get_next_crl_number(crl)))]
        crl.add_extension ef.create_extension("authorityKeyIdentifier",
          "keyid:always,issuer:always")
        crl.sign(ca_private_key, ::OpenSSL::Digest.new("SHA256"))
        crl
      end

      # Return true if a certificate need to be renewed (or doesn't exist) according to the number
      # of days before expiration given
      # @param [string] cert_file path of the cert file or cert content
      # @param [integer] renew_before_expiry number of days before expiration
      # @return [true, false]
      def cert_need_renewal?(cert_file, renew_before_expiry)
        resp = true
        cert_content = ::File.exist?(cert_file) ? File.read(cert_file) : cert_file
        begin
          cert = OpenSSL::X509::Certificate.new cert_content
        rescue ::OpenSSL::X509::CertificateError
          return resp
        end

        unless cert.not_after <= Time.now + 3600 * 24 * renew_before_expiry
          resp = false
        end

        resp
      end

      alias_method :cert_need_renewall?, :cert_need_renewal?

      private

      def __openssl_config
        path = if File.exist?(::OpenSSL::Config::DEFAULT_CONFIG_FILE)
                 OpenSSL::Config::DEFAULT_CONFIG_FILE
               else
                 Dir[File.join(RbConfig::CONFIG["prefix"], "**", "openssl.cnf")].first
               end

        if File.exist?(path)
          ::OpenSSL::Config.load(path)
        else
          Chef::Log.warn("Couldn't find OpenSSL config file")
          nil
        end
      end
    end
  end
end
