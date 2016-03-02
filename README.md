# Mixlib::ShellOut
[![Build Status Master](https://travis-ci.org/chef/mixlib-shellout.svg?branch=master)](https://travis-ci.org/chef/mixlib-shellout) [![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/mixlib-shellout?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/mixlib-shellout/branch/master) [![Gem Version](https://badge.fury.io/rb/mixlib-shellout.svg)](https://badge.fury.io/rb/mixlib-shellout)

Provides a simplified interface to shelling out while still collecting both standard out and standard error and providing full control over environment, working directory, uid, gid, etc.

No means for passing input to the subprocess is provided.

## Example
### Simple Shellout
Invoke find(1) to search for .rb files:

```ruby
  require 'mixlib/shellout'
  find = Mixlib::ShellOut.new("find . -name '*.rb'")
  find.run_command
```

If all went well, the results are on `stdout`

```ruby
  puts find.stdout
```

`find(1)` prints diagnostic info to STDERR:

```ruby
  puts "error messages" + find.stderr
```

Raise an exception if it didn't exit with 0

```ruby
  find.error!
```

### Advanced Shellout
In addition to the command to run there are other options that can be set to change the shellout behavior. The complete list of options can be found here: https://github.com/chef/mixlib-shellout/blob/master/lib/mixlib/shellout.rb

Run a command as the `www` user with no extra ENV settings from `/tmp` with a 1s timeout

```ruby
  cmd = Mixlib::ShellOut.new("apachectl", "start", :user => 'www', :env => nil, :cwd => '/tmp', :timeout => 1)
  cmd.run_command # etc.
```

### STDIN Example
Invoke crontab to edit user cron:

```ruby
  # :input only supports simple strings
  crontab_lines = [ "* * * * * /bin/true", "* * * * * touch /tmp/here" ]
  crontab = Mixlib::ShellOut.new("crontab -l -u #{@new_resource.user}", :input => crontab_lines.join("\n"))
  crontab.run_command
```

### Windows Impersonation Example
Invoke "whoami.exe" to demonstrate running a command as another user:

```ruby
  whoami = Mixlib::ShellOut.new("whoami.exe", :user => "username", :domain => "DOMAIN", :password => "password")
  whoami.run_command
```

## Platform Support
Mixlib::ShellOut does a standard fork/exec on Unix, and uses the Win32 API on Windows. There is not currently support for JRuby.

## See Also
- `Process.spawn` in Ruby 1.9
- [https://github.com/rtomayko/posix-spawn](https://github.com/rtomayko/posix-spawn)

## License
- Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
- License:: Apache License, Version 2.0

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
