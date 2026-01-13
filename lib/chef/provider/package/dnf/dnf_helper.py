#!/usr/bin/env python3
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import dnf
import hawkey
import signal
import os
import json

base = None

def get_sack():
    global base
    if base is None:
        base = dnf.Base()
        conf = base.conf
        conf.read()
        conf.installroot = '/'
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

        if 'repos' in command:
            for repo_pattern in command['repos']:
                if 'enable' in repo_pattern:
                    for repo in repos.get_matching(repo_pattern['enable']):
                        repo.enable()
                if 'disable' in repo_pattern:
                    for repo in repos.get_matching(repo_pattern['disable']):
                        repo.disable()

        try:
            base.configure_plugins()
        except AttributeError:
            pass
        base.fill_sack(load_system_repo='auto')
    return base.sack

# FIXME: leaks memory and does not work
def flushcache():
    try:
        os.remove('/var/cache/dnf/@System.solv')
    except OSError:
        pass
    get_sack().load_system_repo(build_cache=True)

def version_tuple(versionstr):
    e = '0'
    v = None
    r = None
    colon_index = versionstr.find(':')
    if colon_index > 0:
        e = str(versionstr[:colon_index])
    dash_index = versionstr.find('-')
    if dash_index > 0:
        tmp = versionstr[colon_index + 1:dash_index]
        if tmp != '':
            v = tmp
        arch_index = versionstr.rfind('.', dash_index)
        if arch_index > 0:
            r = versionstr[dash_index + 1:arch_index]
        else:
            r = versionstr[dash_index + 1:]
    else:
        tmp = versionstr[colon_index + 1:]
        if tmp != '':
            v = tmp
    return (e, v, r)

def versioncompare(versions):
    sack = get_sack()
    if (versions[0] is None) or (versions[1] is None):
        outpipe.write('0\n')
        outpipe.flush()
    else:
        evr_comparison = dnf.rpm.rpm.labelCompare(version_tuple(versions[0]), version_tuple(versions[1]))
        outpipe.write('{}\n'.format(evr_comparison))
        outpipe.flush()

def query(command):
    sack = get_sack()

    subj = dnf.subject.Subject(command['provides'])
    q = subj.get_best_query(sack, with_provides=True)

    if command['action'] == "whatinstalled":
        q = q.installed()

    if command['action'] == "whatavailable":
        q = q.available()

    if 'epoch' in command:
        # We assume that any glob is "*" so just omit the filter since the dnf libraries have no
        # epoch__glob filter.  That means "?" wildcards in epochs will fail.  The workaround is to
        # not use the version filter here but to put the version with all the globs in the package name.
        if not dnf.util.is_glob_pattern(command['epoch']):
            q = q.filterm(epoch=int(command['epoch']))
    if 'version' in command:
        if dnf.util.is_glob_pattern(command['version']):
            q = q.filterm(version__glob=command['version'])
        else:
            q = q.filterm(version=command['version'])
    if 'release' in command:
        if dnf.util.is_glob_pattern(command['release']):
            q = q.filterm(release__glob=command['release'])
        else:
            q = q.filterm(release=command['release'])

    if 'arch' in command:
        if dnf.util.is_glob_pattern(command['arch']):
            q = q.filterm(arch__glob=command['arch'])
        else:
            q = q.filterm(arch=command['arch'])

    # only apply the default arch query filter if it returns something
    archq = q.filter(arch=[ 'noarch', hawkey.detect_arch() ])
    if len(archq.run()) > 0:
        q = archq

    pkgs = q.latest(1).run()

    if not pkgs:
        outpipe.write('{} nil nil\n'.format(command['provides'].split().pop(0)))
        outpipe.flush()
    else:
        # make sure we picked the package with the highest version
        pkgs.sort
        pkg = pkgs.pop()
        outpipe.write('{} {}:{}-{} {}\n'.format(pkg.name, pkg.epoch, pkg.version, pkg.release, pkg.arch))
        outpipe.flush()

# the design of this helper is that it should try to be 'brittle' and fail hard and exit in order
# to keep process tables clean.  additional error handling should probably be added to the retry loop
# on the ruby side.
def exit_handler(signal, frame):
    if base is not None:
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

        if command['action'] == "whatinstalled":
            query(command)
        elif command['action'] == "whatavailable":
            query(command)
        elif command['action'] == "versioncompare":
            versioncompare(command['versions'])
        else:
            raise RuntimeError("bad command")
finally:
    if base is not None:
        base.close()
