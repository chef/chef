#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

name "libzmq-windows"
default_version "2.2.0"

zmq_installer = "ZeroMQ-#{version}~miru1.0-win32.exe"


source :url => "http://miru.hk/archive/ZeroMQ-#{version}~miru1.0-win32.exe",
       :md5 => "207a322228f90f61bfb67e3f335db06e"

build do

  command "ZeroMQ-#{version}~miru1.0-win32.exe /S /D=%CD%\\zeromq", :returns => [0]

  # Robocopy's return code is 1 if it succesfully copies over the
  # files and 0 if the files are already existing at the destination

  command "robocopy .\\zeromq #{install_dir}\\embedded\\lib\\zeromq /MIR", :returns => [0, 1]

  command ".\\zeromq\\uninstall /S", :returns => [0]

  install_dir_native = install_dir.split(File::SEPARATOR).join(File::ALT_SEPARATOR)

  command "copy /y #{install_dir_native}\\embedded\\lib\\zeromq\\bin\\libzmq-v100-mt.dll #{install_dir_native}\\embedded\\lib\\zeromq\\bin\\libzmq.dll", :returns => [0]
end
