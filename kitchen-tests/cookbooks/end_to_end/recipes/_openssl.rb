# leaving this for the future where we test windows too
base = if platform_family?("windows")
         'C:\ssl_test'
       else
         "/etc/ssl_test"
       end

# Create directory if not already present
directory base do
  recursive true
end

#
# DHPARAM HERE
#

# Generate new key and certificate
openssl_dhparam "#{base}/dhparam.pem" do
  key_length 1024
  action :create
end

#
# RSA KEYS HERE
#

# Generate new key with des3 cipher using the new resource name
openssl_rsa_private_key "#{base}/rsakey_des3.pem" do
  key_length 2048
  action :create
end

# Generate new key with aes-128-cbc cipher with the old resource name
openssl_rsa_key "#{base}/rsakey_aes128cbc.pem" do
  key_length 1024
  key_cipher "aes-128-cbc"
  action :create
end

# we need to do this with a file resource so that chefspec stepping
# into openssl_rsa_public_key can function. It's :(
file "#{base}/private_key.pem" do
  content "-----BEGIN RSA PRIVATE KEY----- Proc-Type: 4,ENCRYPTED DEK-Info: DES-EDE3-CBC,1F2FDA436115C4EE W24gBmtq/Eik2FkSdBh3hF3th3gFq2lMZqSLbho/JVbHFpAQynDbcS9qH5x1fRkt Y7o4A/Sh7noy9kzC1eVIPaQpKFJu5da+uf3t1KxpVMqibzeIE33P9WI+5PzzOm5W xs9shvv/0anU6UMsqBqI+0cmQQ8lw3myTTpO9yWKav2FdTnx7svd+P6BmFknGQaM DYomD0qiB/JzjXbYHLgFspPQXHdyQGhe/YFMlvmjKE0Nut18XJsNwUTWjBA4nRj4 JdlE8XOkWrzIsWKfrBhuhx9bTD0ZVvgssYl2QEh26mv0P0nxx4V/zYx+9U5j0L7q tV4FXfQTgFyctKySuBNi8IT1HFqG9LQps14p8q0XeRigFsRUOVuR0S3eHqg7xiiW QVdF+LgYPpdVNX2mHOSFnHMpFdKLHs8VCNjcGwMNK7avKbne/TJ2NRcL4uhgpsX/ 4tg1kQlwIwtp8MlMqkcinHJ3fjIhWGgjNBVe85NJPVogRDy+c80SqBenaJSavwVA ytmiQOCeon4zhZdscESki+KmsyOWkPB9/zQK76E4ni2IVOL6ZYBMJNTkP47WmA9d Etv7UMxQMI6EYMEH43czvbe4bNCC+hlYotJUM2B52Al7I79W9sSy8cmYi3YZEl0G xtKgY7XwstUBD2XjMuaNyUT0EDjcoa0GhLJSCQkvgn8//BGKaLEyb+Lr+dmHGvxM phCnUKLkfZn9hAFempSJuW4iSaeBKIU3KgYOkBooTuYhXqbN2McoxH6Ec/gnAM5e TIaLiDaHY8IPI4Et5l0sr7v+YF3ZGKC1fL6k4eInNRlhy8oWsFMe79jKkh5wRflt WifTbEdy3D53pVH5lbXyJwpBIOjKJ0OqGWGegu02P5JTsAsniKD+jxNUS8iSOAXL gtpMe4jtqj38hb9D7pBir85Hm+uDqeEuwUqSXAiI+P2F/Jf4ep3h+ek8dcgZtkJQ 3iz92ic2g3M7HW+EE0JcBX+KBwU7yI+UJbWvNQmTXUAYbpoQOLIVm/TrFdGzZ6e9 t0T5wmkE2cS9C3QYiEc7D81nTcTadZChZJDURzUk2REwRGjnunQggHUsj/JKVWqO EPZbpgyDhCaIAkkloWK/SgKny4irMZClhVdeq+v55vDf9nbKR9bgHUb2ZNwp6DQc CPs1BteYthiLtILYzzasMKhlfdoUjEaYziYLGkAQca5XwvwEp0qWg0sMCUUL9pbW 9WzFELBvqNQ1WyIcjb4clcvM0fJdGZ2nKbCAw6zbeSQcGd50NzvTra0xE/J2q6Jo 0V6AGr1Zmu4bJ+tGZCdAIteEO2TosNfS6nrFy15DAe4M4+77ZUGJ8rcwOBopa9qI w7aAyPlfAhrtdSrbOLLp0kRP9EwzSIjSoqc/YJINaNMN8WM7JgnfklmPToT2AqPc 6MOX/Uktag6AXzjcQDtIZSQox326emX1o/huw+7z3/lSXgTdxm3brew/is+9iaQh 5katqPtbec+K/4qydINZSRRFPaoVkg27+6OXvd1AbVS7jmUGHL20xyzA0A9c1csN dm460w4eqbjJEUtDucyIhLPhtYJwPODoRitRmIrzF5DSPrgmSiG93TPiDpRfVPPU -----END RSA PRIVATE KEY-----"
end

openssl_rsa_public_key "#{base}/rsakey_des3.pub" do
  private_key_path "#{base}/rsakey_des3.pem"
  private_key_pass "something"
  action :create
end

openssl_rsa_public_key "#{base}/rsakey_2.pub" do
  private_key_pass "something"
  private_key_content "-----BEGIN RSA PRIVATE KEY-----\nProc-Type: 4,ENCRYPTED\nDEK-Info: DES-EDE3-CBC,5EE0AE9A5FE3342E\n\nyb930kj5/4/nd738dPx6XdbDrMCvqkldaz0rHNw8xsWvwARrl/QSPwROG3WY7ROl\nEUttVlLaeVaqRPfQbmTUfzGI8kTMmDWKjw52gJUx2YJTYRgMHAB0dzYIRjeZAaeS\nypXnEfouVav+jKTmmehr1WuVKbzRhQDBSalzeUwsPi2+fb3Bfuo1dRW6xt8yFuc4\nAkv1hCglymPzPHE2L0nSGjcgA2DZu+/S8/wZ4E63442NHPzO4VlLvpNvJrYpEWq9\nB5mJzcdXPeOTjqd13olNTlOZMaKxu9QShu50GreCTVsl8VRkK8NtwbWuPGBZlIFa\njzlS/RaLuzNzfajaKMkcIYco9t7gN2DwnsACHKqEYT8248Ii3NQ+9/M5YcmpywQj\nWGr0UFCSAdCky1lRjwT+zGQKohr+dVR1GaLem+rSZH94df4YBxDYw4rjsKoEhvXB\nv2Vlx+G7Vl2NFiZzxUKh3MvQLr/NDElpG1pYWDiE0DIG13UqEG++cS870mcEyfFh\nSF2SXYHLWyAhDK0viRDChJyFMduC4E7a2P9DJhL3ZvM0KZ1SLMwROc1XuZ704GwO\nYUqtCX5OOIsTti1Z74jQm9uWFikhgWByhVtu6sYL1YTqtiPJDMFhA560zp/k/qLO\nFKiM4eUWV8AI8AVwT6A4o45N2Ru8S48NQyvh/ADFNrgJbVSeDoYE23+DYKpzbaW9\n00BD/EmUQqaQMc670vmI+CIdcdE7L1zqD6MZN7wtPaRIjx4FJBGsFoeDShr+LoTD\nrwbadwrbc2Rf4DWlvFwLJ4pvNvdtY3wtBu79UCOol0+t8DVVSPVASsh+tp8XncDE\nKRljj88WwBjX7/YlRWvQpe5y2UrsHI0pNy8TA1Xkf6GPr6aS2TvQD5gOrAVReSse\n/kktCzZQotjmY1odvo90Zi6A9NCzkI4ZLgAuhiKDPhxZg61IeLppnfFw0v3H4331\nV9SMYgr1Ftov0++x7q9hFPIHwZp6NHHOhdHNI80XkHqtY/hEvsh7MhFMYCgSY1pa\nK/gMcZ/5Wdg9LwOK6nYRmtPtg6fuqj+jB3Rue5/p9dt4kfom4etCSeJPdvP1Mx2I\neNmyQ/7JN9N87FsfZsIj5OK9OB0fPdj0N0m1mlHM/mFt5UM5x39u13QkCt7skEF+\nyOptXcL629/xwm8eg4EXnKFk330WcYSw+sYmAQ9ZTsBxpCMkz0K4PBTPWWXx63XS\nc4J0r88kbCkMCNv41of8ceeGzFrC74dG7i3IUqZzMzRP8cFeps8auhweUHD2hULs\nXwwtII0YQ6/Fw4hgGQ5//0ASdvAicvH0l1jOQScHzXC2QWNg3GttueB/kmhMeGGm\nsHOJ1rXQ4oEckFvBHOvzjP3kuRHSWFYDx35RjWLAwLCG9odQUApHjLBgFNg9yOR0\njW9a2SGxRvBAfdjTa9ZBBrbjlaF57hq7mXws90P88RpAL+xxCAZUElqeW2Rb2rQ6\nCbz4/AtPekV1CYVodGkPutOsew2zjNqlNH+M8XzfonA60UAH20TEqAgLKwgfgr+a\nc+rXp1AupBxat4EHYJiwXBB9XcVwyp5Z+/dXsYmLXzoMOnp8OFyQ9H8R7y9Y0PEu\n-----END RSA PRIVATE KEY-----\n"
  action :create
end

#
# EC KEYS HERE
#

# Generate a new ec key with key_curve prime256v1 and des3 cipher
openssl_ec_private_key "#{base}/eckey_prime256v1_des3.pem" do
  key_curve "prime256v1"
  key_pass "something"
  action :create
end

openssl_ec_public_key "#{base}/eckey_prime256v1_des3.pub" do
  private_key_path "#{base}/eckey_prime256v1_des3.pem"
  private_key_pass "something"
  action :create
end

openssl_ec_public_key "#{base}/eckey_prime256v1_des3_2.pub" do
  private_key_content "-----BEGIN EC PRIVATE KEY-----\nMHcCAQEEII2VAU9re44mAUzYPWCg+qqwdmP8CplsEg0b/DYPXLg2oAoGCCqGSM49\nAwEHoUQDQgAEKkpMCbIQ2C6Qlp/B+Odp1a9Y06Sm8yqPvCVIkWYP7M8PX5+RmoIv\njGBVf/+mVBx77ji3NpTilMUt2KPZ87lZ3w==\n-----END EC PRIVATE KEY-----\n"
  action :create
end

#
# X509_CERTIFICATE HERE
#

# Generate new key and certificate
openssl_x509 "#{base}/mycert.crt" do
  common_name "mycert.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  subject_alt_name ["IP:127.0.0.1", "DNS:localhost.localdomain"]
end

# Generate a new certificate from an existing key
openssl_x509 "#{base}/mycert2.crt" do
  common_name "mycert2.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  key_file "#{base}/mycert.key"
end

# Generate a new CA certificate
openssl_x509 "#{base}/my_ca.crt" do
  common_name "CA"
  expire 3650
  extensions(
    "keyUsage" => {
      "values" => %w{
        keyCertSign
        keyEncipherment
        digitalSignature
        cRLSign},
      "critical" => true,
    }
  )
end

# Generate and sign a certificate with the CA
openssl_x509_certificate "#{base}/my_signed_cert.crt" do
  common_name "mysignedcert.example.com"
  ca_key_file "#{base}/my_ca.key"
  ca_cert_file "#{base}/my_ca.crt"
  expire 365
  extensions(
    "keyUsage" => {
      "values" => %w{
        keyEncipherment
        digitalSignature},
      "critical" => true,
    },
    "extendedKeyUsage" => {
      "values" => %w{serverAuth},
      "critical" => false,
    }
  )
  subject_alt_name ["IP:127.0.0.1", "DNS:localhost.localdomain"]
end

# Generate CA with CSR and EC key
openssl_ec_private_key "#{base}/my_ca2.key" do
  mode "0400"
  key_curve "secp521r1"
end

openssl_x509_request "The my_ca2.csr cert" do
  path "#{base}/my_ca2.csr"
  common_name "CA2"
  key_file "#{base}/my_ca2.key"
  action :create
end

openssl_x509_certificate "#{base}/my_ca2.crt" do
  csr_file "#{base}/my_ca2.csr"
  ca_key_file "#{base}/my_ca2.key"
  expire 3650
  extensions(
    "keyUsage" => {
      "values" => %w{
        keyCertSign
        keyEncipherment
        digitalSignature
        cRLSign},
      "critical" => true,
    }
  )
end

# Generate key, csr & sign it with CA
openssl_ec_private_key "#{base}/my_signed_cert2.key"

openssl_x509_request "#{base}/my_signed_cert2.csr" do
  common_name "mysignedcert2.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  key_file "#{base}/my_signed_cert2.key"
end

openssl_x509_certificate "#{base}/my_signed_cert2.crt" do
  csr_file "#{base}/my_signed_cert2.csr"
  ca_key_file "#{base}/my_ca2.key"
  ca_cert_file "#{base}/my_ca2.crt"
  expire 365
  extensions(
    "keyUsage" => {
      "values" => %w{
        keyEncipherment
        digitalSignature},
      "critical" => true,
    },
    "extendedKeyUsage" => {
      "values" => %w{serverAuth},
      "critical" => false,
    }
  )
  subject_alt_name ["IP:127.0.0.1", "DNS:localhost.localdomain"]
end

#
# X509_CRL HERE
#

openssl_x509_crl "#{base}/my_ca2.crl" do
  ca_cert_file "#{base}/my_ca2.crt"
  ca_key_file "#{base}/my_ca2.key"
  expire 1
end

openssl_x509_crl "#{base}/my_ca2.crl" do
  ca_cert_file "#{base}/my_ca2.crt"
  ca_key_file "#{base}/my_ca2.key"
  renewal_threshold 2
end

openssl_x509_crl "#{base}/my_ca2.crl" do
  ca_cert_file "#{base}/my_ca2.crt"
  ca_key_file "#{base}/my_ca2.key"
  serial_to_revoke "C7BCB6602A2E4251EF4E2827A228CB52BC0CEA2F"
end

#
# X509_REQUEST HERE
#

# Generate new ec key and csr
openssl_x509_request "#{base}/my_ec_request.csr" do
  common_name "myecrequest.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
end

# Generate a new csr from an existing ec key
openssl_x509_request "#{base}/my_ec_request2.csr" do
  common_name "myecrequest2.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  key_file "#{base}/my_ec_request.key"
end

# Generate new rsa key and csr
openssl_x509_request "#{base}/my_rsa_request.csr" do
  common_name "myrsarequest.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  key_type "rsa"
end

# Generate a new certificate from an existing rsa key
openssl_x509_request "#{base}/my_rsa_request2.csr" do
  common_name "myrsarequest2.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  key_file "#{base}/my_rsa_request.key"
end
