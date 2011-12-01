# Mixlib::ShellOut
Provides a simplified interface to shelling out yet still collecting both
standard out and standard error and providing full control over environment,
working directory, uid, gid, etc.

No means for passing input to the subprocess is provided.

## Platform Support
Mixlib::ShellOut does a standard fork/exec on Unix, and uses the Win32
API on Windows. There is not currently support for JRuby.

## License
Apache 2 Licensed. See LICENSE for full details.

## See Also
* `Process.spawn` in Ruby 1.9
* [https://github.com/rtomayko/posix-spawn](posix-spawn)
