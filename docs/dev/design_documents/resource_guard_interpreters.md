# Resource-based Guard Interpreters for Chef

The *guard interpreter* is a feature of Chef resources that
allows authors to specify their choice of Chef resource classes to evaluate a guard expression (i.e. `only_if` or
`not_if` block). The goal of this capability is to reduce the complexity in both the number of languages
and the boilerplate code found within a Chef recipe.

Guard interpreter customization makes the Chef DSL *Delightful(tm)*.

## Motivation

The original impetus for guard interpreters involved a common user expectation
that when guard expressions were present in a `script` resource, the same
interpreter used to evaluate the `script` resource (e.g. `bash`, `csh`,
`powershell`) would be used to evaluate the guard expression. It turns out
this is not the case -- more on this later -- and thus user expectations were not
being met.

An open source ticket for the Chef project describes a typical instance of
this problem at [CHEF-4553](https://tickets.opscode.com/browse/CHEF-4553). In particular, that
ticket posits that Windows users of the `powershell_script` resource expect
that guards (i.e. the `only_if` and `not_if` conditionals) evaluated in the context of a `powershell_script`
block use the `powershell_script` interpreter, not the cmd.exe (batch file)
interpreter. This is a change from the current state of affairs, since in general there is no link between the interpreter used by a
script resource. This is an issue that affects both Windows and *nix users.

Further detail and motivation for adding these features are given in sections at the
end of the document.

## Problems addressed through guard interpreters

The guard interpreter and related improvements discussed in the document address
the following use cases:

* CHEF-4553: Users of the `powershell_script` resource are forced to execute
  script guards with `CMD`'s batch language instead of the PowerShell
  language already in use in the `powershell_script` resource.
* Users of the bash resource who want to use bash in script guards must explicitly invoke bash with properly quoted
  command arguments in the guard
* Windows users of the `powershell_script` resource do not have a way to use
  PowerShell in script guards in a concise, intuitive, quasi-Boolean fashion,
  while users of the `script`, `csh`, `bash`, and other resources have this
* On Windows, script guards are always executed with the 32-bit process architecture and
  will be affected by the absence of system state exposed only to 64-bit
  processes

## Definitions
This document assumes familiarity with the Chef resource DSL, which is
documented at <http://docs.chef.io/chef/resources.html>.

These definitions are used throughout the discussion:

* **Chef resource or resource:** an element of the Chef DSL that represents configuration, system components, or any other aspect of system state to be managed by Chef.
  The resource contains attributes that define the desired state, and an
  action that can be taken by a provider evaluating the resource such as one
  that changes the actual state of the system the desired state. State such as
  files, scripts, and software packages are examples of system that that can
  be modeled as a Chef resource.
* **guard:** An expression given as an attribute of a Chef resource in the
    form of a string to be executed by a shell or a Ruby block. Such an
    expression is evaluated before running the resource's action, and
    depending on whether it results in a true or false value, will control
    whether or not the resource's action is executed or skipped.
* **script guard:** A guard expression that is given as a string to be
    evaluated by a shell command interpreter. When the interpreter's execution
    of the script results in a successful (i.e. non-zero) process exit code, the guard's value
    is `true`. Otherwise, it is `false`.
* **block guard:** A guard to which a Ruby block is passed rather than a string.
* **guard parameter:** Any Ruby expression passed as additional information to
    the shell interpreter used to modify execution context such as the current
    working directory, environment variables, user identity, etc.
* **guard interpreter resource:** A Chef resource that is not part of a Chef run
    context and is expressed within a block guard's block. The guard interpreter
    resource is simply used to assess a true or false value (e.g. whether a
    script that tests system state in a relevant way returns a success or
    failure process status) inside of a block guard.

## Overview
Guard expressions for all resources have been extended to include an attribute
named `guard_interpreter` that takes the short name symbol of a Chef resource to be
used to evaluate script guards. This is useful for testing conditions to ensure idempotence for non-idempotent resources such as script resources. The goals in doing this are:

* To address [CHEF-4553](https://tickets.opscode.com/browse/CHEF-4553) -- simplify convoluted expressions such as that below for
Windows users
```
not_if 'powershell -noninteractive -noprofile -command "exit [int32]((Get-ExecutionPolicy -scope localmachine) -eq 'RemoteSigned')"'
```
* For guard expressions, to allow Unix and Windows users to make use of familiar modern shells such as
  bash and PowerShell rather than ancient interpreters like `sh` or `cmd.exe` with
  limited or obscure syntax
* To make Chef interactions with OS interfaces such as shells as natural for
  users of the OS as possible

## Behavioral impact on Chef resources
At a high level, here are the changes proposed and now accepted to simplify conditional execution of resource actions:

* Add a `guard_interpreter` attribute to the `Chef::Resource` class that can
  take a symbol that corresponds to the name of a Chef resource derived from
  `Chef::Resource::Script`. This guard interpreter resource will be used to evaluate the script command passed to the guard.
* Truth or falsehood of such a guard is determined by whether the resource
  evaluating the script guard is updated, i.e. runs the script without raising
  an exception and without the script returning a non-success code (0 is the
  default expected success exit code of the script interpreter).
* Parameters passed in hash format after the guard command string are
  interpreted as attributes to be set for the guard interpreter resource instance.
* The guard interpreter resource is executed outside of the containing resource's
  run context.
* Enable inheritance of attributes from a given resource A for any resource B
  executed as part of a block passed to a guard attribute of resource
* Add a `convert_boolean_return` attribute to the `powershell_script` resource
  so that Chef interprets PowerShell `boolean` expressions for PowerShell code
  executed by the `powershell_script` resource such that it returns `boolean`
  values the same way that Unix shells like bash do when they evaluate
  "Boolean-like" statements through commands such as the `test` command
* Make `convert_boolean_return` default to `false` to provide for behavior
  identical to versions of Chef that did not have this feature, but make it
  default to `true` when used to evaluate a guard via the `guard_interpreter`
  attribute to make guard expressions more concise and natural.

## Guard interpreter code examples
The following examples demonstrate the intended use cases around guard
interpreters.
Concepts such as inheritance are introduced in the examples which are explained in subsequent sections.

### Custom interpreter for script resources

```ruby

# This resource will run without errors because the guard uses
# the bash interpreter; if we had passed the same string
# directly to the only_if, this would have failed the
# Chef run since that string is not valid for /bin/sh
bash "Use bash for only_if" do
  guard_interpreter :bash
  code "echo I am $SHELL"
  only_if '[[ 1 == 1 ]]' # won't work outside of bash
end
```

### Inheritance is your friend

```ruby

# This resource will run because the cwd of the guard
# is the same as that of the parent resource
bash "My cwd gets inherited" do
  guard_interpreter :bash
  code 'echo inherit me'
  cwd '/opt'
  only_if '[[ $PWD == "/opt" ]]' # Glad I didn't have to add cwd
end
```

### Setting guard parameters

```ruby

# The normal command string syntax for guards lets you
# specify parameters like cwd, etc. -- you can do the same
# here by specifying those parameters in the guard expression
bash "Override my guard attributes" do
  guard_interpreter :bash
  code 'echo override me'
  cwd '/var'
  only_if '[[ $PWD == "/opt" ]]', :cwd => '/opt' # Don't try to put me in my place
end
```

### `powershell_script` default behavior examples
The examples below are changes to the `powershell_script` resource that take
advantage of guard interpreter resource support.

#### `powershell_script` guard interpreter default example

```ruby

# Here is the fix for CHEF-4553 -- use guard_interpreter to
# execute the script with powershell, not cmd
powershell_script "defaultguard" do
  guard_interpreter :powershell_script
  code 'new-smbshare systemshare $env:systemdrive\'
  not_if 'get-smbshare systemshare' # This uses powershell, not cmd
end
```

#### `powershell_script` Boolean behavior

```ruby

# What if guards evaluated powershell script code that powershell
# evaluates as a boolean type as the actual boolean value of the guard
# itself? You can avoid extra script code to translate the boolean into
# a process exit code that results in the right true / false behavior
# for the guard. Guards already work this way on Linux systems...
powershell_script "set execution policy" do
  guard_interpreter :powershell_script
  code "set-executionpolicy remotesigned"
  not_if "(get-executionpolicy -scope localmachine) -eq 'remotesigned'" # Like I barely left Ruby -- wow!
end
```

#### `powershell_script` architecture inheritance

```ruby
do
# And look, the not_if will run as an :i386 process because of the
# architecture attribute for the parent resource which powershell_script
# guard interpreter resources will inherit from the enclosing resource
powershell_script "set i386 execution policy" do
  guard_interpteter :powershell_script
  architecture :i386
  code "set-executionpolicy remotesigned"
  not_if "(get-executionpolicy -scope localmachine) -eq 'remotesigned'"
end
```

## Guard interpreter formal specification

The documented behavior for guards can be found at
<http://docs.chef.io/resource_common.html>. Guards are expressed via the optional
`not_if` and `only_if` attributes. The expression following the attribute
may be either a block or a string.

### Guard conditional semantics overview

Guards allow for conditional execution of a resource. Before executing the action for the resource, Chef will evaluate the expression to produce a Ruby `true` or
`false` value that is utilized in determining whether to execute the resource's
action or to skip it:

  1. If the **guard_interpreter resource** is **not** specified for the resource, when a string is passed to a guard, the existing implementation executes the `/bin/sh` interpreter on Unix or `cmd.exe` on Windows with that string to be evaluated as a script by the interpreter. Chef will execute the interpreter with the code supplied to the string; if the interpreter exits with a 0 (success) code, this is interpreted as a Ruby `true` value, otherwise it is `false`.
  2. When a block is passed to a guard, the code in the block will be executed,
  and the value of the last line of code executed by the block will be the
  Boolean value of the block, converted to a Boolean value in a manner
  consistent with the Ruby `!!` operator, resulting in either the value `true`
  or `false`.
  3. If the aforementioned string or block expression was supplied to an `only_if` attribute, the action of the resource containing the attribute will be skipped if the expression evaluated to `false` and executed if it evaluated to `true`.
  4. If the expression was supplied to a `not_if` attribute, the behavior of the resource is the inverse of that for `only_if`; the resource action is executed if the expression evaluated to `false` and skipped if it evaluated to `true`.

This specification of guard behavior is accurate without the inclusion of
`guard_interpreter` features described in this document. The
`guard_interpreter` attribute allows for the interpreter to be something other
than `/bin/sh` or `cmd.exe` and is described below.

### Conditional semantics with the guard_interpreter attribute

In Chef Client versions 11.12.0 and later, the `guard_interpreter` attribute
was introduced, which provides the following behavior:

  1. When the `guard_interpreter` attribute is specified in the resource as a value other than `:default`, a **guard interpreter resource** of the type specified in the `guard_interpreter` attribute is created with its `code` attribute set to the value of the string passed to the guard attribute. The guard interpreter resource's action will be executed to produce a truth value.
  2. If the resource action updates the resource, the value is `true`. Resources can only be updated if the interpreter used by the resource specified in the `guard_interpreter` attribute returns a success code, `0` by default, though this can be overridden in attributes specified to the resource as guard arguments. Anything other than a success code results in the guard evaluating as `false`.

### script resource conditional semantics
To enable the usage as guard resources of resources derived from `Chef::Resource::Script`, known colloquially as script resources, all such resources when executed as guard resources will handle the exception `Mixlib::Shellout::ShellCommandFailed`.

By doing this, usage of script resources has the same conditional and exception behavior as the case described earlier when a string is passed to a `not_if` or `only_if` guard attribute since this exception is raised precisely in the case where a string passed as a guard would have been evaluated by /bin/sh or cmd.exe as exiting with a failure status code.

This gives any script resource -- for example, bash -- the ability to behave like the string argument usage for guards, except that an alternative interpreter to `/bin/sh` is used to execute the command. This extends the range of shell script languages that may be used in guard expressions.

### `powershell_script` guard_interpreter example

Use of `guard_interpreter` for the `powershell_script` resource addresses [CHEF-4553](https://tickets.opscode.com/browse/CHEF-4553). Without `guard_interpreter`, a user of the `powershell_script` resource who would like to use the same PowerShell language in the expression passed to the guard resource to the following cumbersome solution:

```ruby
# Yuk. Let me look up all the right cli args to powershell.exe.
# Oh, do I have to quote my cmd -- what kind of quotes again?
# So much fun for me. This is CHEF-4553.
powershell_script "oldguard" do
  code 'new-smbshare systemshare $env:systemdrive'
  not_if 'powershell.exe -inputformat none -noprofile -nologo -noninteractive -command get-smbshare systemshare'
end
```

With the `guard_interpreter` attribute, we have the following more concise, less cumbersome, and less error-prone expression for the same `powershell_script` use case given above:

```ruby
# So PowerShell. Such short.
powershell_script "newguard" do
  guard_interpreter :powershell_script
  code 'new-smbshare systemshare $env:systemdrive'
  not_if 'get-smbshare systemshare'
end
```

### Guard attribute inheritance
A new change is that a resource used within the context of a guard may inherit some attributes from the resource that contains the guard.

Inheritance follows these rules:

* An attribute in a guard interpreter resource is inherited from the parent resource only if the attribute is in a set of inheritable attributes defined by the type of the guard resource
* To be inherited from the parent, the attribute must not have been specified as a parameter to the guard command -- whatever is passed to the guard command will override any parent specification of the attribute.
* The Chef `script` resource, i.e. `Chef::Resource::Script`, and all resources derived from it, including `bash`, `python`, and `powershell_script`, inherit the following attributes from the parent resource:

    `:cwd`
    `:environment`
    `:group`
    `:path`
    `:user`
    `:umask`

* Resource types may define additional rules for inheritance -- the `powershell_script` resource has additional behaviors described in a subsequent section.

In general, the utility of inheritance derives from a common case where setting system configuration through a Chef resource requires some external state such as an environment variable, alternate user identity, or current directory, and testing the current state to ensure idempotence through a guard requires the same state. Inheritance allows that state to be expressed no more than once through the Chef DSL.

### Simplification through attribute inheritance

Consider the following example:

```ruby
script "javatooling" do
  environment {"JAVA_HOME" => '/usr/lib/java/jdk1.7/home'}
  code 'java-based-daemon-ctl.sh -start'
  not_if 'java-based-daemon-ctl.sh -test-started', :environment =>
    {"JAVA_HOME" => '/usr/lib/java/jdk1.7/home'}
end
```

In the `not_if` attribute, the same hash of environment variables specified for
the resource must also be specified for the guard, both of which use a shell script
to that relies on the `JAVA_HOME` environment variable. With inheritance,
the second environment variable specification (along with the possibility of
an incorrect specification) can be eliminated with this simplified version:

```ruby
script "javatooling" do
  guard_interpreter :csh
  environment {"JAVA_HOME" => '/usr/lib/java/jdk1.7/home'}
  code 'java-based-daemon-ctl.sh -start'
  not_if 'java-based-daemon-ctl.sh -test-started'
end
```
#### `powershell_script` inheritance rules

* For the `powershell_script` resource, an additional attribute is inherited
  when this resource is used as a guard resource:

    `:architecture`

* When a guard attribute of `powershell_script` is given a string rather than a
  block, unlike other resources, inheritance of attributes occurs. The
  behavior of the PowerShell interpreter when executing that string is the same
  as if a `powershell_script` resource has been passed instead with the
  `code` attribute set to the value of the string.
* Inherited attributes in this case may be overridden by specifying those same
  attributes as guard parameters using the existing guard parameter syntax

This results in a more concise expression of the resource compared
to the situation without inheritance for string arguments. For example,
without allowing the architecture attribute to be inherited with a string
guard, here is the recipe fragment we'd need to set the PowerShell execution
policy for the x86 PowerShell interpreter:

```ruby
# This is what we'd write if we couldn't inherit the architecture
# attribute when a string is passed to a guard -- we'd repeat
# the architecture attribute twice.
powershell_script "set i386 execution policy" do
  guard_interpreter :powershell_script
  architecture :i386
  code "set-executionpolicy remotesigned"
  not_if "(get-executionpolicy -scope localmachine) -eq 'remotesigned'", :architecture => :i386
end
```

By allowing inheritance, the expression is more compact, requires less
up-front consideration of options, and provides the least surprising behavior:

```ruby
# Much more concise -- architecture attribute is inherited by the guard
powershell_script "set i386 execution policy" do
  guard_interpreter :powershell_script
  architecture :i386
  code "set-executionpolicy remotesigned"
  not_if "(get-executionpolicy -scope localmachine) -eq 'remotesigned'"
end
```

### `powershell_script` Boolean result code interpretation

Boolean result code interpretation allows guards that make use of the
`powershell_script` resource to treat PowerShell Boolean expressions as if they
were Ruby boolean expressions as in the code below:

```ruby
powershell_script "backup-dc" do
  guard_interpreter :powershell_script
  code "backup-domain-controller.ps1"
  only_if "[Security.Principal.WindowsIdentity]::GetCurrent().IsSystem()"
end
```

More formally, the value of guard conditionals for `powershell_script` gets the following
modification:

* The process exit code for a PowerShell script fragment executed by the
  `powershell_script` resource will support passing the value of a *Boolean*
  expression from the script through the interpreter's exit code.
* The attribute `convert_boolean_return` is introduced for the
  `powershell_script` resource to control this behavior -- it may have the
  value `true` or `false`.
* The default value of `convert_boolean_return` is `false` for
  `powershell_script` resource instances that are not being evaluated as a
  guard interpreter resource -- this means that recipes using
  `powershell_script` prior to this change will behave identically after it.
* However, if the `powershell_script` instance exists as the result of
  evaluating a guard expression because the `guard_interpreter` attribute was
  set to `:powershell_script`, the value of `convert_boolean_return` is set to
  `true`. There is no backward compatibility issue for this default because the
  guard_interpreter resource was not available prior to versions of Chef
  with the boolean interpolation feature.
* Boolean interpolation only occurs if the script fragment could have been
  executed as the definition of a PowerShell function with a return type of
  `bool`, a PowerShell type analogous to a typical Boolean data type **AND**
  if the `convert_boolean_return` attribute of the resource executing the
  script is set to `true`.
* In this case, if the function return value is the PowerShell value `$true`,
  the exit code is 0 (overloaded with 'success'), otherwise the function return
  value is `$false` and the exit code is 1.
* In cases where the hypothetical PowerShell function raises an exception or returns a
  type other than PowerShell's `bool` type, preexisting exit code rules hold.

This behavior for `powershell_script` when `convert_boolean_return` is set to
`true` is functionally equivalent to the behavior of the bash shell
when it evaluates quasi-boolean commands such as the `test` command and
related commands.

## Detailed motivation on guard improvements
Particularly for PowerShell users on Windows, the behavior of guards before
Chef 11.12.0 was not delightful. Prior to Chef 11.12.0, when a
string was supplied to a guard, on Unix it was **always** evaluated with
`/bin/sh`, even if the guard was being executed in the context of a script
resource that executes code using something other than sh, like the `bash`
resource. On Windows, there is no `/bin/sh`, so `cmd.exe` was always used for guards.

Both Unix and Windows experiences could have been better in multiple respects. For Windows, `cmd.exe` is
guaranteed to exist on the system, but that's about as much good as you can
say for it. It's a vestigial component that still shows signs of its 1970's
CP/M heritage even in 2014, and as Windows admins turned to PowerShell or were
nudged toward it (often by Microsoft itself), it was asking a lot for Chef users to know
how to use legacy `cmd.exe` to accomplish tasks. Most likely, users of `powershell_script`
would choose to run powershell.exe in the `not_if` and `only_if` blocks. Since
that was the common case for `powersell_script` users, the guards should have
had some way to allow that, or to
provide guard execution via PowerShell in a more natural fashion.

Even for Unix users, however, there was still room to be delightful since
`/bin/sh`, while not the antediluvian relic that is `cmd.exe` on Windows, is
certainly not a modern shell. Thus guards require users of, say, the `bash` resource,
to use two different shell dialects. The bash dialect is a modern and familiar one for the code to be
executed by the script resource, and `sh` is a more limited one for the guards. It's confusing behavior
for new users. And even for those who are experienced,
it requires awkward workarounds like explicitly running bash with some set of
switches and/or researching workarounds for missing features in `sh`. Overall,
it decreases the efficiency of using resources like `bash` -- one might just as
well use the generic script or execute resources if knowledge of the best way
to a given interpreter cannot be contained in the resource.

So the addition of the `guard_interpreter` attribute as adopted via this
design document lets users choose to adopt a more natural way of expressing
idempotence that lets you embed shell-specific expressions in the clean Chef
DSL without all of the awkwardness and corner cases described earlier. The
result is an uncluttered description of infrastructure that doesn't sacrifice
on the shell or underlying platform's native descriptive and functional capabilities.

### Boolean result code interpolation details
Consider the Chef DSL fragment below where a string passed to an `only_if` guard performs a
Boolean test using the sh "[" command:

```ruby
bash "systemrestart" do
  code '~/rebootnow.sh'
  only_if '[ "$USER" == "root" ]'
end
```

This results in the bash script 'rebootnow.sh' being executed only when this
code is executed with chef-client running as root. The Boolean-like expression
in the sh script passed to the guard is treated as a Boolean result for the
guard, resulting in a natural way of using the sh interpreter from within Chef
and Ruby.

A similar mapping between Boolean results for strings passed to guards on the
Windows platform does not exist. This partially due to guards always being
executed with cmd.exe. However, the behavior shown on Unix guards that
interpret script strings is actually present in the script resources
themselves when the same Boolean-like code is executed as part of the `code`
attribute. Here's an example:

```ruby
bash "myfail" do
  code '[ "$USER" == "root" ]'
end
```

If this resource is run as the root user, it will succeed and subsequent
resources in the recipe can be executed. If the user is not root, this will
result in /bin/sh returning a non-zero exit code, and the execution will fail,
terminating any chef-client run.

While the utility of translating Boolean values to interpreter exit codes is debatable within a resource executed
at recipe scope, it is consistent with the much more useful guard behavior
described in the previous example.

Contrast this to the existing `powershell_script` resource, which does not interpolate
Boolean results of scripts to exit codes consistent with truth or falsehood in
any context. The added interpolation for `powershell_script` rectifies the
deficiency in this resource compared to bash and the other Unix shell-based resources.

### PowerShell Boolean symmetry with Unix shells
This boolean interpolation behavior is similar to the `bash` or `sh`
interpreters' behavior in certain contexts, where the
Boolean-like result of the test command causes the interpreter process to exit with 0 if
the test command resulted in a true result, 1 otherwise, assuming the test
command was the last line of the script.

This enables cases where a test that can be expressed very cleanly with
the PowerShell language can be used directly within a guard expression with no
need to try to generate a process exit code that Chef will interpret as a true
or false value. For example, the true or false value of a PowerShell
expression like

    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
      IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

or

    (gi WSMan:\localhost\Shell\MaxMemoryPerShellMB).value -ge 300

can be passed directly to Ruby and evaluated as true or false by the guard
without specifying any additional PowerShell code. This interpolation of
Boolean return values also happens when a string of code is passed to a guard
in a `powershell_script` resource, a scenario that builds on top of the
previously described switch to the PowerShell language as the script interpreter of
strings passed to guards in the `powershell_script` resource.
