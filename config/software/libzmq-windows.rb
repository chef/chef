#
# Copyright 2012-2014 Chef Software, Inc.
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

name "libzmq-windows"
default_version "2.2.0"

zmq_installer = "ZeroMQ-#{version}~miru1.0-win32.exe"

source url: "http://miru.hk/archive/#{zmq_installer}",
       md5: "207a322228f90f61bfb67e3f335db06e"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  tmpdir = File.join(Omnibus::Config.cache_dir, "libzmq-cache")

  command "#{zmq_installer} /S /D=#{windows_safe_path(tmpdir)}", env: env

  copy "#{tmpdir}/bin/*", "#{install_dir}/embedded/bin"
  copy "#{tmpdir}/include/*", "#{install_dir}/embedded/include"
  copy "#{tmpdir}/lib/*", "#{install_dir}/embedded/lib"

  # Ensure the main DLL is available under a well known name.
  copy "#{tmpdir}/bin/libzmq-v100-mt.dll", "#{install_dir}/embedded/bin/libzmq.dll"

  command "uninstall /S", cwd: tmpdir, env: env
end
