# s3_access_key "something"
# s3_secret_key "something"

s3_bucket "opscode-omnibus-cache"
use_s3_caching true
solaris_compiler "gcc"
build_dmg true
sign_pkg true
signing_identity "Developer ID Installer: Opscode Inc. (9NBR9JL2R2)"
