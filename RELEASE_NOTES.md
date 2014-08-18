# Chef Client 10.34.0 Release Notes:

## DSCL user provider now supports Mac OS X 10.7 and above.

DSCL user provider in Chef has supported setting passwords only on Mac OS X 10.6. In this release, Mac OS X versions 10.7 and above are now supported. Support for Mac OS X 10.6 is dropped from the dscl provider since this version is EOLed by Apple.

In order to support configuring passwords for the users using shadow hashes two new attributes `salt` & `iterations` are added to the user resource. These attributes are required to make the new [SALTED-SHA512-PBKDF2](http://en.wikipedia.org/wiki/PBKDF2) style shadow hashes used in Mac OS X versions 10.8 and above.

User resource on Mac supports setting password both using plain-text password or using the shadow hash. You can simply set the `password` attribute to the plain text password to configure the password for the user. However this is not ideal since including plain text passwords in cookbooks (even if they are private) is not a good idea. In order to set passwords using shadow hash you can follow the instructions below based on your Mac OS X version.

### Mac OS X 10.7

10.7 calculates the password hash using **SALTED-SHA512**. Stored shadow hash length is 68 bytes; first 4 bytes being salt and the next 64 bytes being the shadow hash itself. You can use below code in order to calculate password hashes to be used in `password` attribute on Mac OS X 10.7:

```
password = "my_awesome_password"
salt = OpenSSL::Random.random_bytes(4)
encoded_password = OpenSSL::Digest::SHA512.hexdigest(salt + password)
shadow_hash = salt.unpack('H*').first + encoded_password

# You can use this value in your recipes as below:

user "my_awesome_user" do
  password "c9b3bd....d843"  # Length: 136
end
```
### Mac OS X 10.8 and above

10.7 calculates the password hash using **SALTED-SHA512-PBKDF2**. Stored shadow hash length is 128 bytes. In addition to the shadow hash value, `salt` (32 bytes) and `iterations` (integer) is stored on the system. You can use below code in order to calculate password hashes on Mac OS X 10.8 and above:

```
password = "my_awesome_password"
salt = OpenSSL::Random.random_bytes(32)
iterations = 25000 # Any value above 20k should be fine.

shadow_hash = OpenSSL::PKCS5::pbkdf2_hmac(
  password,
  salt,
  iterations,
  128,
  OpenSSL::Digest::SHA512.new
).unpack('H*').first
salt_value = salt.unpack('H*').first

# You can use this value in your recipes as below:

user "my_awesome_user" do
  password "cbd1a....fc843"  # Length: 256
  salt "bd1a....fc83"        # Length: 64
  iterations 25000
end
```
