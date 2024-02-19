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
#

name "openssl"

license "OpenSSL"
license_file "LICENSE"
skip_transitive_dependency_licensing true

dependency "cacerts"
dependency "openssl-fips" if fips_mode?

default_version "3.0.9" # do_not_auto_update

# Openssl builds engines as libraries into a special directory. We need to include
# that directory in lib_dirs so omnibus can sign them during macOS deep signing.
lib_dirs lib_dirs.concat(["#{install_dir}/embedded/lib/engines"])
lib_dirs lib_dirs.concat(["#{install_dir}/embedded/lib/engines-1.1"]) if version.start_with?("1.1")
if version.start_with?("3.")
  lib_dirs lib_dirs.concat(["#{install_dir}/embedded/lib/engines-3"])
  lib_dirs lib_dirs.concat(["#{install_dir}/embedded/lib/ossl-modules"])
end

# 1.0.2u was the last public release of 1.0.2. Subsequent releases come from a support contract with OpenSSL Software Services
if version.satisfies?("< 1.1.0")
  source url: "https://s3.amazonaws.com/chef-releng/openssl/openssl-#{version}.tar.gz", extract: :lax_tar
  internal_source url: "#{ENV["ARTIFACTORY_REPO_URL"]}/#{name}/#{name}-#{version}.tar.gz", extract: :lax_tar,
                  authorization: "X-JFrog-Art-Api:#{ENV["ARTIFACTORY_TOKEN"]}"
else
  # As of 2020-09-09 even openssl-1.0.0.tar.gz can be downloaded from /source/openssl-VERSION.tar.gz
  # However, the latest releases are not in /source/old/VERSION/openssl-VERSION.tar.gz.
  # Let's stick with the simpler one for now.
  source url: "https://www.openssl.org/source/openssl-#{version}.tar.gz", extract: :lax_tar
  internal_source url: "#{ENV["ARTIFACTORY_REPO_URL"]}/#{name}/#{name}-#{version}.tar.gz", extract: :lax_tar,
                  authorization: "X-JFrog-Art-Api:#{ENV["ARTIFACTORY_TOKEN"]}"
end

version("3.0.11")  { source sha256: "b3425d3bb4a2218d0697eb41f7fc0cdede016ed19ca49d168b78e8d947887f55" }
version("3.0.9")   { source sha256: "eb1ab04781474360f77c318ab89d8c5a03abc38e63d65a603cabbf1b00a1dc90" }
version("3.0.5")   { source sha256: "aa7d8d9bef71ad6525c55ba11e5f4397889ce49c2c9349dcea6d3e4f0b024a7a" }
version("3.0.4")   { source sha256: "2831843e9a668a0ab478e7020ad63d2d65e51f72977472dc73efcefbafc0c00f" }
version("3.0.3")   { source sha256: "ee0078adcef1de5f003c62c80cc96527721609c6f3bb42b7795df31f8b558c0b" }
version("3.0.1")   { source sha256: "c311ad853353bce796edad01a862c50a8a587f62e7e2100ef465ab53ec9b06d1" } # only ruby 3.1 supports openssl-3.0.1

version("1.1.1t")  { source sha256: "8dee9b24bdb1dcbf0c3d1e9b02fb8f6bf22165e807f45adeb7c9677536859d3b" }
version("1.1.1q")  { source sha256: "d7939ce614029cdff0b6c20f0e2e5703158a489a72b2507b8bd51bf8c8fd10ca" }
version("1.1.1p")  { source sha256: "bf61b62aaa66c7c7639942a94de4c9ae8280c08f17d4eac2e44644d9fc8ace6f" }
version("1.1.1o")  { source sha256: "9384a2b0570dd80358841464677115df785edb941c71211f75076d72fe6b438f" }
version("1.1.1m")  { source sha256: "f89199be8b23ca45fc7cb9f1d8d3ee67312318286ad030f5316aca6462db6c96" }
version("1.1.1l")  { source sha256: "0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1" }
version("1.1.1w")  { source sha256: "cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8" }

version("1.0.2zg") { source sha256: "09f8372eaede77ec8e6945e2d2d8eeb1b91662980cf23fe95f627b377162296c" }
version("1.0.2zb") { source sha256: "b7d8f8c895279caa651e7f3de9a7b87b8dd01a452ca3d9327f45a9ef31d0c518" }
version("1.0.2za") { source sha256: "86ec5d2ecb53839e9ec999db7f8715d0eb7e534d8a1d8688ef25280fbeee2ff8" }
version("1.0.2ze") { source sha256: "796624c593c361c695bd16314bc6f944184f5d2ff87efcf0bfa0545aa84c4d88" }
version("1.0.2zf") { source sha256: "85d2242b7d11a33d5f239f1f34a1ff7eb37431a554b7df99c52c646b70b14b2e" }
version("1.0.2zi") { source sha256: "80b6c07995fc92456e31c61cf1b2a18f75e314063189bb183af6ae66d0261d84" }

relative_path "openssl-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  if aix?
    env["M4"] = "/opt/freeware/bin/m4"
  elsif mac_os_x? && arm?
    env["CFLAGS"] << " -Qunused-arguments"
  elsif windows?
    # XXX: OpenSSL explicitly sets -march=i486 and expects that to be honored.
    # It has OPENSSL_IA32_SSE2 controlling whether it emits optimized SSE2 code
    # and the 32-bit calling convention involving XMM registers is...  vague.
    # Do not enable SSE2 generally because the hand optimized assembly will
    # overwrite registers that mingw expects to get preserved.
    env["CFLAGS"] = "-I#{install_dir}/embedded/include"
    env["CPPFLAGS"] = env["CFLAGS"]
    env["CXXFLAGS"] = env["CFLAGS"]
  end

  configure_args = [
    "--prefix=#{install_dir}/embedded",
    "no-unit-test",
    "no-comp",
    "no-idea",
    "no-mdc2",
    "no-rc5",
    "no-ssl2",
    "no-ssl3",
    "no-zlib",
    "shared",
  ]

  configure_args += ["--libdir=#{install_dir}/embedded/lib"] if version.satisfies?(">=3.0.1")

  # https://www.openssl.org/blog/blog/2021/09/13/LetsEncryptRootCertExpire/
  configure_args += [ "-DOPENSSL_TRUSTED_FIRST_DEFAULT" ] if version.satisfies?(">= 1.0.2zb") && version.satisfies?("< 1.1.0")

  if version.satisfies?("< 3.0.0")
    configure_args += ["--with-fipsdir=#{install_dir}/embedded", "fips"] if fips_mode?
  else
    configure_args += ["-enable-fips"] if fips_mode?
  end

  configure_cmd =
    if aix?
      "perl ./Configure aix64-cc"
    elsif mac_os_x?
      intel? ? "./Configure darwin64-x86_64-cc" : "./Configure darwin64-arm64-cc no-asm"
    elsif smartos?
      "/bin/bash ./Configure solaris64-x86_64-gcc -static-libgcc"
    elsif omnios?
      "/bin/bash ./Configure solaris-x86-gcc"
    elsif solaris2?
      platform = sparc? ? "solaris64-sparcv9-gcc" : "solaris64-x86_64-gcc"
      if version.satisfies?("< 1.1.0")
        "/bin/bash ./Configure #{platform} -static-libgcc"
      else
        "./Configure #{platform} -static-libgcc"
      end
    elsif windows?
      platform = windows_arch_i386? ? "mingw" : "mingw64"
      "perl.exe ./Configure #{platform}"
    else
      prefix =
        if linux? && ppc64?
          "./Configure linux-ppc64"
        elsif linux? && s390x?
          # With gcc > 4.3 on s390x there is an error building
          # with inline asm enabled
          "./Configure linux64-s390x -DOPENSSL_NO_INLINE_ASM"
        else
          "./config"
        end
      "#{prefix} disable-gost"
    end

  patch_env = if aix?
                # This enables omnibus to use 'makedepend'
                # from fileset 'X11.adt.imake' (AIX install media)
                env["PATH"] = "/usr/lpp/X11/bin:#{ENV["PATH"]}"
                penv = env.dup
                penv["PATH"] = "/opt/freeware/bin:#{env["PATH"]}"
                penv
              else
                env
              end

  if version.start_with? "1.0"
    patch source: "openssl-1.0.1f-do-not-build-docs.patch", env: patch_env
  elsif version.start_with? "1.1"
    patch source: "openssl-1.1.0f-do-not-install-docs.patch", env: patch_env
  elsif version.start_with? "3.0"
    patch source: "openssl-3.0.1-do-not-install-docs.patch", env: patch_env
    # Some of the algorithms which are being used are deprecated in OpenSSL3 and moved to legacy provider.
    # We need those algorithms for the working of chef-workstation and other packages.
    # This patch will enable the legacy providers!
    configure_args << "enable-legacy"
    patch source: "openssl-3.0.0-enable-legacy-provider.patch", env: patch_env
  end

  if version.start_with?("1.0.2") && mac_os_x? && arm?
    patch source: "openssl-1.0.2x-darwin-arm64.patch"
  end

  if version.start_with?("1.0.2") && windows?
    # Patch Makefile.org to update the compiler flags/options table for mingw.
    patch source: "openssl-1.0.1q-fix-compiler-flags-table-for-msys.patch", env: env
  end

  # Out of abundance of caution, we put the feature flags first and then
  # the crazy platform specific compiler flags at the end.
  configure_args << env["CFLAGS"]

  configure_command = configure_args.unshift(configure_cmd).join(" ")

  command configure_command, env: env, in_msys_bash: true

  if version.start_with?("1.0.2") && windows?
    patch source: "openssl-1.0.1j-windows-relocate-dll.patch", env: env
  end

  make "depend", env: env
  # make -j N on openssl is not reliable
  make env: env
  if aix?
    # We have to sudo this because you can't actually run slibclean without being root.
    # Something in openssl changed in the build process so now it loads the libcrypto
    # and libssl libraries into AIX's shared library space during the first part of the
    # compile. This means we need to clear the space since it's not being used and we
    # can't install the library that is already in use. Ideally we would patch openssl
    # to make this not be an issue.
    # Bug Ref: http://rt.openssl.org/Ticket/Display.html?id=2986&user=guest&pass=guest
    command "sudo /usr/sbin/slibclean", env: env
  end
  make "install", env: env
end