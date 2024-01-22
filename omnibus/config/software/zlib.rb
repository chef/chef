#
# Copyright 2012-2018 Chef Software, Inc.
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

name "zlib"
default_version "1.2.13"

# version_list: url=https://zlib.net/fossils/ filter=*.tar.gz

version("1.3")    { source sha256: "ff0ba4c292013dbc27530b3a81e1f9a813cd39de01ca5e0f8bf355702efa593e" }
version("1.2.13") { source sha256: "b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30" }
version("1.2.12") { source sha256: "91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9" }
version("1.2.11") { source sha256: "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1" }
version("1.2.8")  { source sha256: "36658cb768a54c1d4dec43c3116c27ed893e88b02ecfcb44f2166f9c0b7f2a0d" }
version("1.2.6")  { source sha256: "21235e08552e6feba09ea5e8d750805b3391c62fb81c71a235c0044dc7a8a61b" }

source url: "https://zlib.net/fossils/zlib-#{version}.tar.gz"
internal_source url: "#{ENV["ARTIFACTORY_REPO_URL"]}/#{name}/#{name}-#{version}.tar.gz",
                authorization: "X-JFrog-Art-Api:#{ENV["ARTIFACTORY_TOKEN"]}"

license "Zlib"
license_file "README"
skip_transitive_dependency_licensing true

relative_path "zlib-#{version}"

build do
  if windows?
    env = with_standard_compiler_flags(with_embedded_path)

    patch source: "zlib-windows-relocate.patch", env: env

    # We can't use the top-level Makefile. Instead, the developers have made
    # an organic, artisanal, hand-crafted Makefile.gcc for us which takes a few
    # variables.
    env["BINARY_PATH"] = "/bin"
    env["LIBRARY_PATH"] = "/lib"
    env["INCLUDE_PATH"] = "/include"
    env["DESTDIR"] = "#{install_dir}/embedded"

    make_args = [
      "-fwin32/Makefile.gcc",
      "SHARED_MODE=1",
      "CFLAGS=\"#{env["CFLAGS"]} -Wall\"",
      "ASFLAGS=\"#{env["CFLAGS"]} -Wall\"",
      "LDFLAGS=\"#{env["LDFLAGS"]}\"",
      # The win32 makefile for zlib does not handle parallel make correctly.
      # In particular, see its rule for IMPLIB and SHAREDLIB. The ld step in
      # SHAREDLIB will generate both the dll and the dll.a files. The step to
      # strip the dll occurs next but since the dll.a file is already present,
      # make will attempt to link example_d.exe and minigzip_d.exe in parallel
      # with the strip step - causing gcc to freak out when a source file is
      # rewritten part way through the linking stage.
      # "-j #{workers}",
    ]

    make(*make_args, env: env)
    # Debug output
    puts "*********DEBUG FROM Omnibus-s/w : bin_path :"
    puts env["BINARY_PATH"]
    puts " dest_dir : "
    puts env["DESTDIR"]
    puts "********"

    make("install", *make_args, env: env)
  else
    # We omit the omnibus path here because it breaks mac_os_x builds by picking
    # up the embedded libtool instead of the system libtool which the zlib
    # configure script cannot handle.
    # TODO: Do other OSes need this?  Is this strictly a mac thing?
    env = with_standard_compiler_flags
    if freebsd? || solaris2?
      # FreeBSD 10+ gets cranky if zlib is not compiled in a
      # position-independent way.
      # zlib 1.2.12 introduced the same problem on Solaris.
      env["CFLAGS"] << " -fPIC"
    end

    configure env: env
    
    # Debug output
    puts "*********DEBUG FROM Omnibus-s/w : bin_path :"
    puts env["BINARY_PATH"]
    puts " dest_dir : "
    puts env["DESTDIR"]
    puts "********"
    
    make "-j #{workers}", env: env
    make "-j #{workers} install", env: env
  end
end
