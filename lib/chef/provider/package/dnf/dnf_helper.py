#!/usr/bin/env python3
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Meta Platforms, Inc.
# Copyright:: Copyright (c) 2026 Phil Dibowitz
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

import sys
import signal
import os
import json

# to enable debug logging, set the CHEF_DNF_HELPER_DEBUG_FILE environment
# variable to a file path
DEBUG_FILE = os.environ.get("CHEF_DNF_HELPER_DEBUG_FILE", None)

# Try to import dnf5 first, fall back to dnf4
try:
    import libdnf5
    import rpm

    DNF_VERSION = 5
except ImportError:
    try:
        import dnf
        import hawkey

        DNF_VERSION = 4
    except ImportError:
        raise RuntimeError(
            "Neither dnf5 (libdnf5) nor dnf4 (dnf) libraries are available"
        )

base = None


def get_base_dnf5(command):
    global base
    if base is None:
        base = libdnf5.base.Base()

        # Load configuration
        base.load_config()

        # Set up vars
        base.setup()

        # Load repositories
        repo_sack = base.get_repo_sack()
        repo_sack.create_repos_from_system_configuration()

        if "repos" in command:
            for repo_pattern in command["repos"]:
                if "enable" in repo_pattern:
                    query = libdnf5.repo.RepoQuery(base)
                    query.filter_id(
                        repo_pattern["enable"], libdnf5.common.QueryCmp_GLOB
                    )
                    for repo in query:
                        repo.enable()
                if "disable" in repo_pattern:
                    query = libdnf5.repo.RepoQuery(base)
                    query.filter_id(
                        repo_pattern["disable"], libdnf5.common.QueryCmp_GLOB
                    )
                    for repo in query:
                        repo.disable()

        # Load repositories and create solv files
        repo_sack.load_repos()

    return base


def get_sack_dnf4(command):
    global base
    if base is None:
        base = dnf.Base()
        conf = base.conf
        conf.read()
        conf.installroot = "/"
        conf.assumeyes = True
        subst = conf.substitutions
        subst.update_from_etc(conf.installroot)
        try:
            base.init_plugins()
            base.pre_configure_plugins()
        except AttributeError:
            pass
        base.read_all_repos()
        repos = base.repos

        if "repos" in command:
            for repo_pattern in command["repos"]:
                if "enable" in repo_pattern:
                    for repo in repos.get_matching(repo_pattern["enable"]):
                        repo.enable()
                if "disable" in repo_pattern:
                    for repo in repos.get_matching(repo_pattern["disable"]):
                        repo.disable()

        try:
            base.configure_plugins()
        except AttributeError:
            pass
        base.fill_sack(load_system_repo="auto")
    return base.sack


def get_sack(command):
    if DNF_VERSION == 5:
        return get_base_dnf5(command)
    else:
        return get_sack_dnf4(command)


def version_tuple(versionstr):
    e = "0"
    v = None
    r = None
    colon_index = versionstr.find(":")
    if colon_index > 0:
        e = str(versionstr[:colon_index])
    dash_index = versionstr.find("-")
    if dash_index > 0:
        tmp = versionstr[colon_index + 1 : dash_index]
        if tmp != "":
            v = tmp
        arch_index = versionstr.rfind(".", dash_index)
        if arch_index > 0:
            r = versionstr[dash_index + 1 : arch_index]
        else:
            r = versionstr[dash_index + 1 :]
    else:
        tmp = versionstr[colon_index + 1 :]
        if tmp != "":
            v = tmp
    return (e, v, r)


# If we pass in 0:1.10 and 1.2 to the dnf5 libraries, it won't compare
# them correctly, they both need to have epochs or not have epochs. However,
# unlike dnf4 libraries, it they don't take tuples, so use version_tuple to
# canonicalize the parts of the version, then reassemble them into a full EVR
# string.
def version_canonicalize(versionstr):
    e, v, r = version_tuple(versionstr)
    return f"{e}:{v}-{r}"


def versioncompare(command):
    versions = command["versions"]
    sack = get_sack(command)
    if (versions[0] is None) or (versions[1] is None):
        outpipe.write("0\n")
        outpipe.flush()
    else:
        if DNF_VERSION == 4:
            evr_comparison = dnf.rpm.rpm.labelCompare(
                version_tuple(versions[0]), version_tuple(versions[1])
            )
            outpipe.write("{}\n".format(evr_comparison))
        else:
            # dnf5 version comparison - rpmvercmp handles full EVR strings
            cmp_result = libdnf5.rpm.rpmvercmp(
                version_canonicalize(versions[0]),
                version_canonicalize(versions[1]),
            )
            outpipe.write("{}\n".format(cmp_result))
        outpipe.flush()


def query_dnf4(command):
    sack = get_sack(command)

    subj = dnf.subject.Subject(command["provides"])
    q = subj.get_best_query(sack, with_provides=True)

    if command["action"] == "whatinstalled":
        # When attempting to figure out what is installed, we should ignore any
        # excludes that are configured, otherwise the "best" query for a given
        # subject may refer to a package that is installed that provides that
        # subject, but we really want to know if a package by that name exists
        # in any available repository
        q = subj.get_best_query(
            sack,
            with_provides=True,
            query=sack.query(flags=hawkey.IGNORE_EXCLUDES),
        )
        q = q.installed()

    if command["action"] == "whatavailable":
        q = q.available()

    if "epoch" in command:
        # We assume that any glob is "*" so just omit the filter since the dnf libraries have no
        # epoch__glob filter.  That means "?" wildcards in epochs will fail.  The workaround is to
        # not use the version filter here but to put the version with all the globs in the package name.
        if not dnf.util.is_glob_pattern(command["epoch"]):
            q = q.filterm(epoch=int(command["epoch"]))
    if "version" in command:
        if dnf.util.is_glob_pattern(command["version"]):
            q = q.filterm(version__glob=command["version"])
        else:
            q = q.filterm(version=command["version"])
    if "release" in command:
        if dnf.util.is_glob_pattern(command["release"]):
            q = q.filterm(release__glob=command["release"])
        else:
            q = q.filterm(release=command["release"])

    if "arch" in command:
        if dnf.util.is_glob_pattern(command["arch"]):
            q = q.filterm(arch__glob=command["arch"])
        else:
            q = q.filterm(arch=command["arch"])

    # only apply the default arch query filter if it returns something
    archq = q.filter(arch=["noarch", hawkey.detect_arch()])
    if len(archq.run()) > 0:
        q = archq

    pkgs = q.latest(1).run()

    if not pkgs:
        outpipe.write("{} nil nil\n".format(command["provides"].split().pop(0)))
        outpipe.flush()
    else:
        # make sure we picked the package with the highest version
        pkgs.sort
        pkg = pkgs.pop()
        outpipe.write(
            "{} {}:{}-{} {}\n".format(
                pkg.name, pkg.epoch, pkg.version, pkg.release, pkg.arch
            )
        )
        outpipe.flush()


def log(message):
    if DEBUG_FILE is None:
        return
    with open(DEBUG_FILE, "a") as f:
        f.write(message + "\n")


def query_dnf5(command):
    """
    Query dnf5 for package information based on the command dict.

    This method does a fair amount of work to try to mimic the behavior
    of "dnf install <foo>". In the DNF4 world, this functionality was
    exposed through the dnf.subject.Subject class. In DNF5, this functionality
    is internal to the Goal class, which you can use, but then you can't get
    a list of matching packages out of - you can simply ask the goal to be
    resolved to a package transaction, and then run or not run that transaction.

    So instead we combine the nevra filtering and provides filtering to mimic
    the behavior of being able to handle anything that could be passed to
    "dnf install <foo>".

    Some of the cases we handle are:
    - name only: "foo"
    - name and arch: "foo.x86_64"
    - name and version: "foo-1.2"
    - name, version, release: "foo-1.2-3"
    - name, version, release, arch: "foo-1.2-3.x
    - name with version constraint: "foo >= 1.2"
    - globs: "foo*", "foo-1.2*", "foo-1.2-3*", "foo-1*.*", etc.

    A full exercising of this functionality testing all known cases is
    in the unittest for the DNF provider.
    """
    base = get_sack(command)
    q = libdnf5.rpm.PackageQuery(base)

    # First, we need to know if this parses as a nevra or not, which will
    # inform the rest of our decision tree.
    provides_str = command["provides"]
    try:
        nevra_vector = libdnf5.rpm.Nevra.parse(provides_str)
    except libdnf5.exception.RpmNevraIncorrectInputError:
        # when parse() throws an this exception, it's because there's spaces,
        # or other special characters in it, and the only valid things passed
        # to us that fit that category are constrains like: "foo >= 1.2". So
        # parse it as one of those, add the constraint to the query, and update
        # the name we search for to the parsed name
        nevra_vector = []
        reldep = libdnf5.rpm.Reldep(base, provides_str)
        provides_str = reldep.get_name()
        q.filter_provides(reldep)

    # unlike the old subject based query, filter_nevra doesn't handle
    # the <name>.<arch> case properly. Further, adding * to arch causes
    # weirdness. So, we detect the arch suffix, and strip it off and add
    # it to the direct arch filter.
    #
    # Unfortunately, since we want to support nearly any possible combination
    # of name, version, release, arch with globs, we have to do some extra work
    # here. parse() will give us an iterable list of possible interpretations
    # of the string. That can include dumb things like for "foo-1.2" the
    # possibility that "2" is an arch. So, we take the arch and see if it's
    # a compatible arch with us (e.g. x86_64 and i686 on x86_64 systems). If
    # we find one that matches, we use that, rip the arch off, add it to the
    # filters.
    #
    # While there may be other entries in the list that are (more) correct,
    # it doesn't matter, we're only need to detect if a valid arch was specified
    # so we can handle that manually.
    nevra = None
    for n in nevra_vector:
        log(
            f"  => Possible interpretation: n:{n.get_name()} v:{n.get_version()} r:{n.get_release()} a:{n.get_arch()}"
        )
        arch = n.get_arch()
        if arch != "" and rpm.archscore(arch) > 0:
            log(f"  => Selected interpretation with arch: {arch}")
            nevra = n
            break

    # if we found a nevra with a valid arch, use that arch
    if nevra is not None:
        arch = nevra.get_arch()
        name = nevra.get_name()
        if arch and provides_str.endswith(arch):
            command["arch"] = nevra.get_arch()
            # strip of ".<arch>" from the end of provides_str
            provides_str = provides_str[: -(len(arch) + 1)]

    # in order to get the behavior of "dnf install <blah>" we have to add
    # '*' to the end in order to make stuff like "chef_rpm-1.2" work.
    if not provides_str.endswith("*"):
        provides_str += "*"

    log(f"  => provides_str after processing: {provides_str}")
    log(f"  => command after processing: {command}")
    if command["action"] == "whatinstalled":
        q.filter_installed()

    if command["action"] == "whatavailable":
        q.filter_available()

    # Apply version filters
    if "epoch" in command:
        if "*" not in command["epoch"] and "?" not in command["epoch"]:
            q.filter_epoch(int(command["epoch"]))

    if "version" in command:
        if "*" in command["version"] or "?" in command["version"]:
            q.filter_version(command["version"], libdnf5.common.QueryCmp_GLOB)
        else:
            q.filter_version(command["version"])

    if "release" in command:
        if "*" in command["release"] or "?" in command["release"]:
            q.filter_release(command["release"], libdnf5.common.QueryCmp_GLOB)
        else:
            q.filter_release(command["release"])

    if "arch" in command:
        if "*" in command["arch"] or "?" in command["arch"]:
            q.filter_arch(command["arch"], libdnf5.common.QueryCmp_GLOB)
        else:
            q.filter_arch(command["arch"])

    # now, we try by nevra search, and *IF* that returns nothing, then
    # do a provides search. Combined with the work above to handle various
    # name conventions, this gets is roughly compatible with the old
    # dnf4 "subject" calls.
    nevra_q = libdnf5.rpm.PackageQuery(q)
    nevra_q.filter_nevra(provides_str, libdnf5.common.QueryCmp_GLOB)
    if not nevra_q.empty():
        q = nevra_q
    else:
        q.filter_provides(provides_str, libdnf5.common.QueryCmp_GLOB)

    # Filter by architecture (prefer noarch and native arch)
    # Get the system architecture from vars
    detected_arch = base.get_vars().get_value("arch")
    archq = libdnf5.rpm.PackageQuery(q)
    archq.filter_arch(["noarch", detected_arch])

    if not archq.empty():
        q = archq

    # Get latest packages
    q.filter_latest_evr()

    pkgs = list(q)
    log(f"  => pkgs from query: {pkgs}")

    if not pkgs:
        outpipe.write("{} nil nil\n".format(command["provides"].split().pop(0)))
        outpipe.flush()
    else:
        # Sort and get the highest version
        pkgs.sort(
            key=lambda p: (p.get_epoch(), p.get_version(), p.get_release()),
            reverse=True,
        )
        pkg = pkgs[0]
        outpipe.write(
            "{} {}:{}-{} {}\n".format(
                pkg.get_name(),
                pkg.get_epoch(),
                pkg.get_version(),
                pkg.get_release(),
                pkg.get_arch(),
            )
        )
        outpipe.flush()


def query(command):
    if DNF_VERSION == 5:
        query_dnf5(command)
    else:
        query_dnf4(command)


# the design of this helper is that it should try to be 'brittle' and fail hard and exit in order
# to keep process tables clean.  additional error handling should probably be added to the retry loop
# on the ruby side.
def exit_handler(signal, frame):
    if DNF_VERSION == 4 and base is not None:
        base.close()
    sys.exit(0)


def setup_exit_handler():
    signal.signal(signal.SIGINT, exit_handler)
    signal.signal(signal.SIGHUP, exit_handler)
    signal.signal(signal.SIGPIPE, exit_handler)
    signal.signal(signal.SIGQUIT, exit_handler)


if len(sys.argv) < 3:
    inpipe = sys.stdin
    outpipe = sys.stdout
else:
    os.set_blocking(int(sys.argv[1]), True)
    inpipe = os.fdopen(int(sys.argv[1]), "r")
    outpipe = os.fdopen(int(sys.argv[2]), "w")

try:
    setup_exit_handler()
    while 1:
        # stop the process if the parent proc goes away
        ppid = os.getppid()
        if ppid == 1:
            raise RuntimeError("orphaned")

        line = inpipe.readline()

        # only way to detect EOF in python
        if line == "":
            break

        try:
            command = json.loads(line)
        except ValueError:
            raise RuntimeError("bad json parse")

        log(f"COMMAND: {command}")
        if command["action"] == "whatinstalled":
            query(command)
        elif command["action"] == "whatavailable":
            query(command)
        elif command["action"] == "versioncompare":
            versioncompare(command)
        else:
            raise RuntimeError("bad command")
finally:
    if DNF_VERSION == 4 and base is not None:
        base.close()
