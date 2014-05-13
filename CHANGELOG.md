# mixlib-shellout Changelog

## Unreleased

* Improved process cleanup on timeouts.
* Enabled travis.
* Added error? to check if the command ran successfully. MIXLIB-18.
* Remove GC.disable hack for non-ruby 1.8.8
* Handle ESRCH from getpgid of a zombie on OS X
* Fix "TypeError: no implicit conversion from nil to integer" due to nil "token" passed to CloseHandle. MIXLIB-25.
* $stderr of the command process is now reflected in the live_stream in addition to $stdout. (MIXLIB-19)
## Last Release: 1.3.0 (12/03/2013)
