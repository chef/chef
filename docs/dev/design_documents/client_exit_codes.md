# Chef-Client Exit Codes

Chef-client exit codes signal outside tools to the result of the Chef-Client run.

## Motivation

    As a Chef user,
    I want to be able to determine when a chef-client run is rebooting the node,
    so that Test-Kitchen/Vagrant/any outside tool can wait for the node to reboot, and continue converging.

## Specification

* Chef applications (e.g. chef-client) that interpret recipes should use the specified exit codes
* Chef tools (e.g. knife) should behave appropriately for the exit code, or pass it to the user

### Exit codes Reserved by Operating System

* Windows- [Link](https://msdn.microsoft.com/en-us/library/windows/desktop/ms681381(v=vs.85).aspx)
* Linux - [Sysexits](http://www.freebsd.org/cgi/man.cgi?query=sysexits&apropos=0&sektion=0&manpath=FreeBSD+4.3-RELEASE&format=html), [Bash Scripting](http://tldp.org/LDP/abs/html/exitcodes.html)

### Remaining Available Exit Codes

All exit codes defined should be usable on all supported Chef Platforms. Also, the exit codes used should be identical across all platforms. That limits the total range from 1-255. Exit codes not explicitly used by Linux/Windows are listed below. There are 59 exit codes that are available on both platforms.
 * Any numbers below that have a strike-through are used below in the **Exit Codes in Use** section
 * Exit Codes Available for Chef use :
     * ~~35,37,40,41,42~~,43,44,45,46,47,48,49,79,81,90,91,92,93,94,95,96,97
     * 98,99,115,116,168,169,172,175,176,177,178,179,181,184,185,204,211
     * ~~213~~,219,227,228,235,236,237,238,239,241,242,243,244,245

### Precedence

* Reboot exit codes should take precedence over Chef Execution State
* Precedence within a table should be evaluated from the top down.

## Exit Codes in Use

#### Reboot Requirement

Exit Code        | Reason            | Details
-------------    | -------------     |-----
35               | Reboot Scheduled  | Reboot has been scheduled in the run state
37               | Reboot Needed     | Reboot needs to be completed
41               | Reboot Failed     | Initiated Reboot failed - due to permissions or any other reason


#### Chef Run State

Exit Code        | Reason             | Details
-------------    | -------------      |-----
-1               | Failed execution*   | Generic error during Chef execution.  On Linux this will show up as 255, on Windows as -1
0                | Successful run     | Any successful execution of a Chef utility should return this exit code
1                | Failed execution   | Generic error during Chef execution.
2                | SIGINT received    | Received an interrupt signal
3                | SIGTERM received   | Received an terminate signal
42               | Audit Mode Failure | Audit mode failed, but chef converged successfully.
213              | Chef upgrade       | Chef has exited during a client upgrade

* \*Next release should deprecate any use of this exit code.

## Extend

If there is a need for additional exit codes, please open a Design Proposal PR to discuss the change, and then a PR to update this document.
