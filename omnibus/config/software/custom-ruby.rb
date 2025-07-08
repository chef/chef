name "custom-ruby"
default_version "3.3.1"

# Point to your custom Ruby location in Artifactory
source url: "#{ENV['ARTIFACTORY_BASE_URL'] || 'https://artifactory-internal.ps.chef.co/artifactory'}/omnibus-software-local/ruby/ruby-#{version}.tar.gz",
       sha256: "8dc2af2802cc700cd182d5430726388ccf885b3f0a14fcd6a0f21ff249c9aa99"

relative_path "ruby-#{version}"

# Add dependencies for building Ruby (but NOT chef-foundation)
dependency "zlib"
dependency "openssl"
dependency "libffi"
dependency "libyaml"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Build commands for Ruby
  command "./configure --prefix=#{install_dir}/embedded --with-out-ext=dbm,gdbm,readline --enable-shared --disable-install-doc --without-gmp --disable-dtrace", env: env
  make "-j #{workers}", env: env
  make "install", env: env
end