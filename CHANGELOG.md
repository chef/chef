# mixlib-shellout Changelog

## Unreleased

## Release: 2.0.1

* add buffering to the child process status pipe to fix chef-client deadlocks
* fix timeouts on Windows

## Release: 2.0.0

* remove LC_ALL=C default setting, consumers should now set this if they
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
