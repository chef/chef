#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "provider/batch"
require_relative "provider/cookbook_file"
require_relative "provider/cron"
require_relative "provider/cron/solaris"
require_relative "provider/cron/aix"
require_relative "provider/directory"
require_relative "provider/dsc_script"
require_relative "provider/dsc_resource"
require_relative "provider/execute"
require_relative "provider/file"
require_relative "provider/git"
require_relative "provider/group"
require_relative "provider/http_request"
require_relative "provider/ifconfig"
require_relative "provider/launchd"
require_relative "provider/link"
require_relative "provider/mount"
require_relative "provider/noop"
require_relative "provider/package"
require_relative "provider/powershell_script"
require_relative "provider/remote_directory"
require_relative "provider/remote_file"
require_relative "provider/route"
require_relative "provider/ruby_block"
require_relative "provider/script"
require_relative "provider/service"
require_relative "provider/subversion"
require_relative "provider/systemd_unit"
require_relative "provider/template"
require_relative "provider/user"
require_relative "provider/whyrun_safe_ruby_block"
require_relative "provider/yum_repository"
require_relative "provider/zypper_repository"

require_relative "provider/package/apt"
require_relative "provider/package/chocolatey"
require_relative "provider/package/dpkg"
require_relative "provider/package/dnf"
require_relative "provider/package/freebsd/port"
require_relative "provider/package/freebsd/pkgng"
require_relative "provider/package/homebrew"
require_relative "provider/package/ips"
require_relative "provider/package/macports"
require_relative "provider/package/openbsd"
require_relative "provider/package/pacman"
require_relative "provider/package/portage"
require_relative "provider/package/paludis"
require_relative "provider/package/rpm"
require_relative "provider/package/rubygems"
require_relative "provider/package/yum"
require_relative "provider/package/zypper"
require_relative "provider/package/solaris"
require_relative "provider/package/smartos"
require_relative "provider/package/bff"
require_relative "provider/package/cab"
require_relative "provider/package/powershell"
require_relative "provider/package/msu"
require_relative "provider/package/snap"

require_relative "provider/service/arch"
require_relative "provider/service/freebsd"
require_relative "provider/service/gentoo"
require_relative "provider/service/init"
require_relative "provider/service/invokercd"
require_relative "provider/service/debian"
require_relative "provider/service/openbsd"
require_relative "provider/service/redhat"
require_relative "provider/service/insserv"
require_relative "provider/service/simple"
require_relative "provider/service/systemd"
require_relative "provider/service/upstart"
require_relative "provider/service/windows"
require_relative "provider/service/solaris"
require_relative "provider/service/macosx"
require_relative "provider/service/aixinit"
require_relative "provider/service/aix"

require_relative "provider/user/aix"
require_relative "provider/user/linux"
require_relative "provider/user/mac"
require_relative "provider/user/pw"
require_relative "provider/user/solaris"
require_relative "provider/user/windows"

require_relative "provider/group/aix"
require_relative "provider/group/dscl"
require_relative "provider/group/gpasswd"
require_relative "provider/group/groupadd"
require_relative "provider/group/groupmod"
require_relative "provider/group/pw"
require_relative "provider/group/solaris"
require_relative "provider/group/suse"
require_relative "provider/group/usermod"
require_relative "provider/group/windows"

require_relative "provider/mount/mount"
require_relative "provider/mount/aix"
require_relative "provider/mount/solaris"
require_relative "provider/mount/windows"
require_relative "provider/mount/linux"

require_relative "provider/remote_file/ftp"
require_relative "provider/remote_file/sftp"
require_relative "provider/remote_file/http"
require_relative "provider/remote_file/local_file"
require_relative "provider/remote_file/network_file"
require_relative "provider/remote_file/fetcher"

require_relative "provider/lwrp_base"
require_relative "provider/registry_key"

require_relative "provider/file/content"
require_relative "provider/remote_file/content"
require_relative "provider/cookbook_file/content"
require_relative "provider/template/content"

require_relative "provider/ifconfig/redhat"
require_relative "provider/ifconfig/debian"
require_relative "provider/ifconfig/aix"
