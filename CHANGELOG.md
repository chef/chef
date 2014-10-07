# mixlib-shellout Changelog

## Last Release: 1.6.0

* [**Steven Proctor**:](https://github.com/stevenproctor)
  Updated link to posix-spawn in README.md.
* [**Akshay Karle**:](https://github.com/akshaykarle)
  Added the functionality to reflect $stderr when using live_stream.
* [**Tyler Cipriani**:](https://github.com/thcipriani)
  Fixed typos in the code.
* [**Max Lincoln**](https://github.com/maxlinc):
  Support separate live stream for stderr.

* Use `close_others` flag instead of `#clean_parent_file_descriptors()` during
  child clean up.

## Last Release: 1.4.0

* [**Chris Armstrong**:](https://github.com/carmstrong)
  Added error? to check if the command ran successfully. MIXLIB-18.

* Improved process cleanup on timeouts.
* Enabled travis.
* Remove GC.disable hack for non-ruby 1.8.8
* Handle ESRCH from getpgid of a zombie on OS X
* Fix "TypeError: no implicit conversion from nil to integer" due to nil "token" passed to CloseHandle. MIXLIB-25.
* $stderr of the command process is now reflected in the live_stream in addition to $stdout. (MIXLIB-19)
