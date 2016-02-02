#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright 2009-2016, Matthew Kent
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
# subject to most of the configuration parameters in yum.conf. yum-dump will
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
from distutils import version

YUM_PID_FILE='/var/run/yum.pid'

YUM_VER = version.StrictVersion(yum.__version__)
YUM_MAJOR = YUM_VER.version[0]

if YUM_MAJOR > 3 or YUM_MAJOR < 2:
  print >> sys.stderr, "yum-dump Error: Can't match supported yum version" \
    " (%s)" % yum.__version__
  sys.exit(1)

# Required for Provides output
if YUM_MAJOR == 2:
  import rpm
  import rpmUtils.miscutils

def setup(yb, options):
  # Only want our output
  #
  if YUM_MAJOR == 3:
    try:
      if YUM_VER >= version.StrictVersion("3.2.22"):
        yb.preconf.errorlevel=0
        yb.preconf.debuglevel=0

        # initialize the config
        yb.conf
      else:
        yb.doConfigSetup(errorlevel=0, debuglevel=0)
    except yum.Errors.ConfigError, e:
      # suppresses an ignored exception at exit
      yb.preconf = None
      print >> sys.stderr, "yum-dump Config Error: %s" % e
      return 1
    except ValueError, e:
      yb.preconf = None
      print >> sys.stderr, "yum-dump Options Error: %s" % e
      return 1
  elif YUM_MAJOR == 2:
    yb.doConfigSetup()

    def __log(a,b): pass

    yb.log = __log
    yb.errorlog = __log

  # Give Chef every possible package version, it can decide what to do with them
  if YUM_MAJOR == 3:
    yb.conf.showdupesfromrepos = True
  elif YUM_MAJOR == 2:
    yb.conf.setConfigOption('showdupesfromrepos', True)

  # Optionally run only on cached repositories, but non root must use the cache
  if os.geteuid() != 0:
    if YUM_MAJOR == 3:
      yb.conf.cache = True
    elif YUM_MAJOR == 2:
      yb.conf.setConfigOption('cache', True)
  else:
    if YUM_MAJOR == 3:
      yb.conf.cache = options.cache
    elif YUM_MAJOR == 2:
      yb.conf.setConfigOption('cache', options.cache)

  # Handle repo toggle via id or glob exactly like yum
  for opt, repos in options.repo_control:
      for repo in repos:
        if opt == '--enablerepo':
            yb.repos.enableRepo(repo)
        elif opt == '--disablerepo':
            yb.repos.disableRepo(repo)

  return 0

def dump_packages(yb, list, output_provides):
  packages = {}

  if YUM_MAJOR == 2:
    yb.doTsSetup()
    yb.doRepoSetup()
    yb.doSackSetup()

  db = yb.doPackageLists(list)

  for pkg in db.installed:
    pkg.type = 'i'
    packages[str(pkg)] = pkg

  if YUM_VER >= version.StrictVersion("3.2.21"):
    for pkg in db.available:
      pkg.type = 'a'
      packages[str(pkg)] = pkg

    # These are both installed and available
    for pkg in db.reinstall_available:
      pkg.type = 'r'
      packages[str(pkg)] = pkg
  else:
    # Old style method - no reinstall list
    for pkg in yb.pkgSack.returnPackages():

      if str(pkg) in packages:
        if packages[str(pkg)].type == "i":
          packages[str(pkg)].type = 'r'
          continue

      pkg.type = 'a'
      packages[str(pkg)] = pkg

  unique_packages = packages.values()

  unique_packages.sort(lambda x, y: cmp(x.name, y.name))

  for pkg in unique_packages:
    if output_provides == "all" or \
        (output_provides == "installed" and (pkg.type == "i" or pkg.type == "r")):

      # yum 2 doesn't have provides_print, implement it ourselves using methods
      # based on requires gathering in packages.py
      if YUM_MAJOR == 2:
        provlist = []

        # Installed and available are gathered in different ways
        if pkg.type == 'i' or pkg.type == 'r':
          names = pkg.hdr[rpm.RPMTAG_PROVIDENAME]
          flags = pkg.hdr[rpm.RPMTAG_PROVIDEFLAGS]
          ver = pkg.hdr[rpm.RPMTAG_PROVIDEVERSION]
          if names is not None:
            tmplst = zip(names, flags, ver)

          for (n, f, v) in tmplst:
            prov = rpmUtils.miscutils.formatRequire(n, v, f)
            provlist.append(prov)
        # This is slow :(
        elif pkg.type == 'a':
          for prcoTuple in pkg.returnPrco('provides'):
              prcostr = pkg.prcoPrintable(prcoTuple)
              provlist.append(prcostr)

        provides = provlist
      else:
        provides = pkg.provides_print
    else:
      provides = "[]"

    print '%s %s %s %s %s %s %s %s' % (
      pkg.name,
      pkg.epoch,
      pkg.version,
      pkg.release,
      pkg.arch,
      provides,
      pkg.type,
      pkg.repoid )

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
    return dump_packages(yb, options.package_list, options.output_provides)

  # Wrap the collection and output of packages in yum's global lock to prevent
  # any inconsistencies.
  try:
    # Spin up to --yum-lock-timeout option
    countdown = options.yum_lock_timeout
    while True:
      try:
        yb.doLock(YUM_PID_FILE)
        lock_obtained = True
      except Errors.LockError, e:
        time.sleep(1)
        countdown -= 1
        if countdown == 0:
           print >> sys.stderr, "yum-dump Locking Error! Couldn't obtain an " \
             "exclusive yum lock in %d seconds. Giving up." % options.yum_lock_timeout
           return 200
      else:
        break

    return dump_packages(yb, options.package_list, options.output_provides)

  # Ensure we clear the lock and cleanup any resources
  finally:
    try:
      yb.closeRpmDB()
      if lock_obtained == True:
        yb.doUnlock(YUM_PID_FILE)
    except Errors.LockError, e:
      print >> sys.stderr, "yum-dump Unlock Error: %s" % e
      return 200

# Preserve order of enable/disable repo args like yum does
def gather_repo_opts(option, opt, value, parser):
  if getattr(parser.values, option.dest, None) is None:
    setattr(parser.values, option.dest, [])
  getattr(parser.values, option.dest).append((opt, value.split(',')))

def main():
  usage = "Usage: %prog [options]\n" + \
          "Output a list of installed, available and re-installable packages via yum"
  parser = OptionParser(usage=usage)
  parser.add_option("-C", "--cache",
                    action="store_true", dest="cache", default=False,
                    help="run entirely from cache, don't update cache")
  parser.add_option("-o", "--options",
                    action="store_true", dest="output_options", default=False,
                    help="output select yum options useful to Chef")
  parser.add_option("-p", "--installed-provides",
                    action="store_const", const="installed", dest="output_provides", default="none",
                    help="output Provides for installed packages, big/wide output")
  parser.add_option("-P", "--all-provides",
                    action="store_const", const="all", dest="output_provides", default="none",
                    help="output Provides for all package, slow, big/wide output")
  parser.add_option("-i", "--installed",
                    action="store_const", const="installed", dest="package_list", default="all",
                    help="output only installed packages")
  parser.add_option("-a", "--available",
                    action="store_const", const="available", dest="package_list", default="all",
                    help="output only available and re-installable packages")
  parser.add_option("--enablerepo",
                    action="callback",  callback=gather_repo_opts, type="string", dest="repo_control", default=[],
                    help="enable disabled repositories by id or glob")
  parser.add_option("--disablerepo",
                    action="callback",  callback=gather_repo_opts, type="string", dest="repo_control", default=[],
                    help="disable repositories by id or glob")
  parser.add_option("--yum-lock-timeout",
                    action="store",  type="int", dest="yum_lock_timeout", default=30,
                    help="Time in seconds to wait for yum process lock")

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
# Suppress a nasty broken pipe error when output is piped to utilities like 'head'
except IOError, e:
  if e.errno == errno.EPIPE:
    sys.exit(1)
  else:
    raise

sys.exit(status)
