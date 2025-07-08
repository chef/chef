name "custom-ruby"
default_version "3.1.4" # Your desired Ruby version

# Point to your custom Ruby location in Artifactory
source url: "#{ENV['ARTIFACTORY_BASE_URL'] || 'https://your-artifactory-instance.example.com/artifactory'}/path/to/repo/ruby-#{version}.tar.gz",
       sha256: "abc123def456789...your_sha256_checksum_here"

# For Windows, you might use:
if windows?
  source url: "#{ENV['ARTIFACTORY_BASE_URL']}/path/to/repo/ruby-#{version}-x64-mingw-ucrt.zip",
         sha256: "your_windows_sha256_checksum"
end

relative_path "ruby-#{version}"

# Make sure chef-foundation is built before this
dependency "chef-foundation" 

build do
  env = with_standard_compiler_flags(with_embedded_path)

  if windows?
    # For Windows, we might just extract a pre-built Ruby
    copy "#{project_dir}/bin/*", "#{install_dir}/embedded/bin/"
    copy "#{project_dir}/lib/ruby", "#{install_dir}/embedded/lib/"
  else
    # For Unix, build from source
    command "./configure --prefix=#{install_dir}/embedded --with-out-ext=dbm,gdbm,readline --enable-shared --disable-install-doc --without-gmp --disable-dtrace", env: env
    
    make "-j #{workers}", env: env
    make "install", env: env
  end
end