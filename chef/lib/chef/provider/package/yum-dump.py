#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2009, 2011 Matthew Kent
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

# yum-dump.py
# Inspired by yumhelper.py by David Lutterkort
#
# Produce a list of installed, available and re-installable packages using yum
# and dump the results to stdout.
#
# yum-dump invokes yum similarly to the command line interface which makes it
# subject to most of the configuration paramaters in yum.conf. yum-dump will
# also load yum plugins in the same manor as yum - these can affect the output.
#
# Can be run as non root, but that won't update the cache.
#
# Intended to support yum 2.x and 3.x

import os
import sys
import time
import yum
import re
import errno

from yum import Errors
from optparse import OptionParser

YUM_PID_FILE='/var/run/yum.pid'

# Seconds to wait for exclusive access to yum
LOCK_TIMEOUT = 10

if re.search(r"^3\.", yum.__version__):
  YUM_VER = 3
elif re.search(r"^2\.", yum.__version__):
  YUM_VER = 2
else:
  print >> sys.stderr, "yum-dump Error: Can't match supported yum version" \
    " (%s)" % yum.__version__
  sys.exit(1)

def setup(yb, options):
  # Only want our output
  #
  if YUM_VER == 3:
    try:
      yb.preconf.errorlevel=0
      yb.preconf.debuglevel=0

      # initialize the config
      yb.conf
    except yum.Errors.ConfigError, e:
      # supresses an ignored exception at exit
      yb.preconf = None 
      print >> sys.stderr, "yum-dump Config Error: %s" % e
      return 1
    except ValueError, e:
      yb.preconf = None 
      print >> sys.stderr, "yum-dump Options Error: %s" % e
      return 1
  elif YUM_VER == 2:
    yb.doConfigSetup()

    def __log(a,b): pass

    yb.log = __log
    yb.errorlog = __log

  # Give Chef every possible package version, it can decide what to do with them
  if YUM_VER == 3:
    yb.conf.showdupesfromrepos = True
  elif YUM_VER == 2:
    yb.conf.setConfigOption('showdupesfromrepos', True)

  # Optionally run only on cached repositories, but non root must use the cache
  if os.geteuid() != 0:
    if YUM_VER == 3:
      yb.conf.cache = True
    elif YUM_VER == 2:
      yb.conf.setConfigOption('cache', True)
  else:
    if YUM_VER == 3:
      yb.conf.cache = options.cache
    elif YUM_VER == 2:
      yb.conf.setConfigOption('cache', options.cache)

  return 0

def dump_packages(yb, list):
  packages = {}

  if YUM_VER == 2:
    yb.doTsSetup()
    yb.doRepoSetup()
    yb.doSackSetup()

  db = yb.doPackageLists(list)
  
  for pkg in db.installed:
    pkg.type = 'i'
    # __str__ contains epoch, name etc
    packages[str(pkg)] = pkg

  for pkg in db.available:
    pkg.type = 'a'
    packages[str(pkg)] = pkg

  # These are both installed and available
  for pkg in db.reinstall_available:
    pkg.type = 'r'
    packages[str(pkg)] = pkg
   
  unique_packages = packages.values()

  unique_packages.sort(lambda x, y: cmp(x.name, y.name))

  for pkg in unique_packages:
    print '%s %s %s %s %s %s' % ( pkg.name,
                                  pkg.epoch,
                                  pkg.version,
                                  pkg.release,
                                  pkg.arch,
                                  pkg.type )
  return 0

def yum_dump(options):
  lock_obtained = False

  yb = yum.YumBase()

  status = setup(yb, options)
  if status != 0:
    return status

  if options.output_options:
    print "[option installonlypkgs] %s" % " ".join(yb.conf.installonlypkgs)

  # Non root can't handle locking on rhel/centos 4
  if os.geteuid() != 0:
    return dump_packages(yb, options.package_list)

  # Wrap the collection and output of packages in yum's global lock to prevent
  # any inconsistencies.
  try:
    # Spin up to LOCK_TIMEOUT
    countdown = LOCK_TIMEOUT
    while True:
      try:
        yb.doLock(YUM_PID_FILE)
        lock_obtained = True
      except Errors.LockError, e:
        time.sleep(1)
        countdown -= 1 
        if countdown == 0:
           print >> sys.stderr, "yum-dump Locking Error! Couldn't obtain an " \
             "exclusive yum lock in %d seconds. Giving up." % LOCK_TIMEOUT
           return 200
      else:
        break

    return dump_packages(yb, options.package_list)

  # Ensure we clear the lock and cleanup any resources
  finally:
    try:
      yb.closeRpmDB()
      if lock_obtained == True:
        yb.doUnlock(YUM_PID_FILE)
    except Errors.LockError, e:
      print >> sys.stderr, "yum-dump Unlock Error: %s" % e
      return 200

def main():
  usage = "Usage: %prog [options]\n" + \
          "Output a list of installed, available and re-installable packages via yum"
  parser = OptionParser(usage=usage)
  parser.add_option("-o", "--options",
                    action="store_true", dest="output_options", default=False,
                    help="output select yum options useful to Chef")
  parser.add_option("-C", "--cache",
                    action="store_true", dest="cache", default=False,
                    help="run entirely from cache, don't update cache")
  parser.add_option("-i", "--installed",
                    action="store_const", const="installed", dest="package_list", default="all",
                    help="output only installed packages")
  parser.add_option("-a", "--available",
                    action="store_const", const="available", dest="package_list", default="all",
                    help="output only available and re-installable packages")
  
  (options, args) = parser.parse_args()

  try:
    return yum_dump(options)

  except yum.Errors.RepoError, e:
    print >> sys.stderr, "yum-dump Repository Error: %s" % e
    return 1
 
  except yum.Errors.YumBaseError, e:
    print >> sys.stderr, "yum-dump General Error: %s" % e
    return 1

try:
  status = main()
# Suppress a nasty broken pipe error when output is piped to utilities like
# 'head'
except IOError, e:
  if e.errno == errno.EPIPE:
    sys.exit(1)
  else:
    raise

sys.exit(status)
