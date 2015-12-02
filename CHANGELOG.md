# mixlib-shellout Changelog

## Release 2.2.4

* [**tschuy**:](https://github.com/tschuy)
  convert environment hash keys to strings

## Release 2.2.3

* Kill all child processes on Windows when a command times out.

## Release 2.2.2

* Ship gemspec and Gemfiles to facilate testing.
* Fix #111 by pulling in an updated version of win-32/process and correctly patching Process::create.
* Kill all child processes on Windows when a command times out.

## Release 2.2.1

* Fix executable resolution on Windows when a directory exists with the same name as the command to run

## Release 2.2.0

* Remove windows-pr dependency

## Release 2.1.0

* [**BackSlasher**:](https://github.com/BackSlasher)
  `login` flag now correctly does the magic on unix to simulate a login
  shell for a user (secondary groups, environment variables, set primary group and
  generally emulate `su -`).
* went back to setsid() to drop the controlling tty, fixed old AIX issue with
  getpgid() via avoiding calling getpgid().
* converted specs to rspec3

## Release: 2.0.1

* add buffering to the child process status pipe to fix chef-client deadlocks
* fix timeouts on Windows

## Release: 2.0.0

* remove `LC_ALL=C` default setting, consumers should now set this if they
  still need it.
* Change the minimum required version of Ruby to >= 1.9.3.

## Release: 1.6.0

* [**Steven Proctor**:](https://github.com/stevenproctor)
  Updated link to posix-spawn in README.md.
* [**Akshay Karle**:](https://github.com/akshaykarle)
  Added the functionality to reflect $stderr when using live_stream.
* [**Tyler Cipriani**:](https://github.com/thcipriani)
  Fixed typos in the code.
* [**Max Lincoln**](https://github.com/maxlinc):
  Support separate live stream for stderr.
