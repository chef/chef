#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2009 Matthew Kent
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

# yum-dump-json.py
# Inspired by yumhelper.py by David Lutterkort
#
# Produce a list of installed and available packages using yum and dump the 
# result as json to stdout.
#
# This invokes yum just as the command line would which makes it subject to 
# all the caching related configuration paramaters in yum.conf.
#
# Can be run as non root, but that won't update the cache.

import os
import sys
import yum
import json

y = yum.YumBase()
# Only want json in output
y.doConfigSetup(debuglevel=0, errorlevel=0)

# yum assumes it can update the cache directory. Disable this for non root 
# users.
y.conf.cache = os.geteuid() != 0

y.doTsSetup()
y.doRpmDBSetup()

db = y.doPackageLists('all')

y.closeRpmDB()

combined = {}

for pkg in db.installed:
     combined[pkg.name] = {}
     combined[pkg.name]["installed"] = { "epoch": pkg.epoch,
                                         "version": pkg.version,
                                         "release": pkg.release,
                                         "arch": pkg.arch }
for pkg in db.available:
     if not combined.has_key(pkg.name):
         combined[pkg.name] = {}
         combined[pkg.name]["available"] = { "epoch": pkg.epoch,
                                             "version": pkg.version,
                                             "release": pkg.release,
                                             "arch": pkg.arch }
print json.write( combined )

sys.exit(0)
