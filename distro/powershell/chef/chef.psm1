function Get-ScriptDirectory {
  if (!$PSScriptRoot) {
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    $PSScriptRoot = Split-Path $Invocation.MyCommand.Path
  }
  $PSScriptRoot
}

function Run-RubyCommand($command, $argList) {
  # This method exists to take the given list of arguments and get it past ruby's command-line
  # interpreter unscathed and untampered.  See https://github.com/ruby/ruby/blob/trunk/win32/win32.c#L1582
  # for a list of transformations that ruby attempts to perform with your command-line arguments
  # before passing it onto a script.  The most important task is to defeat the globbing
  # and wild-card expansion that ruby performs.  Note that ruby does not use MSVCRT's argc/argv
  # and deliberately reparses the raw command-line instead.
  #
  # To stop ruby from interpreting command-line arguments as globs, they need to be enclosed in '
  # Ruby doesn't allow any escape characters inside '.  This unfortunately prevents us from sending
  # any strings which themselves contain '.  Ruby does allow multi-fragment arguments though.
  # "foo bar"'baz qux'123"foo" is interpreted as 1 argument because there are no un-escaped
  # whitespace there.  The argument would be interpreted as the string "foo barbaz qux123foo".
  # This lets us escape ' characters by exiting the ' quoted string, injecting a "'" fragment and
  # then resuming the ' quoted string again.
  #
  # In the process of defeating ruby, one must also defeat the helpfulness of powershell.
  # When arguments come into this method, the standard PS rules for interpreting cmdlet arguments
  # apply.  When using & (call operator) and providing an array of arguments, powershell will not
  # evaluate them but (contrary to documentation), it will still marginally interpret them.  If any
  # of the provided arguments has a space in it, powershell checks the first and last character to
  # ensure that they are " characters (and that's all it checks).  If they are not, it will blindly
  # surround that argument with " characters.  It won't do this operation if no space is present,
  # even if other special characters are present. If it notices leading and trailing " characters,
  # it won't actually check to see if there are other " characters in the string.
  #
  # In case you think that you're either reading this incorrectly or that I'm full of shit, here
  # are some examples.  These use EchoArgs.exe from the PowerShell Community Extensions package.
  # I have not included the argument parsing output from EchoArgs.exe to prevent confusing you with
  # more details about MSVCRT's parsing algorithm.
  #
  # $x = "foo '' bar `"baz`""
  # & EchoArgs @($x, $x)
  # Command line:
  # "C:\Program Files (x86)\PowerShell Community Extensions\Pscx3\Pscx\Apps\EchoArgs.exe"  "foo '' bar "baz"" "foo '' bar "baz""
  #
  # $x = "abc'123'nospace`"lulz`"!!!"
  # & EchoArgs @($x, $x)
  # Command line:
  # "C:\Program Files (x86)\PowerShell Community Extensions\Pscx3\Pscx\Apps\EchoArgs.exe"  abc'123'nospace"lulz"!!! abc'123'nospace"lulz"!!!
  #
  # $x = "`"`"Look ma! Tonnes of spaces! 'foo' 'bar'`"`""
  # & EchoArgs @($x, $x)
  # Command line:
  # "C:\Program Files (x86)\PowerShell Community Extensions\Pscx3\Pscx\Apps\EchoArgs.exe"  ""Look ma! Tonnes of spaces! 'foo' 'bar'"" ""Look ma! Tonnes of spaces! 'foo' 'bar'""
  # 
  # Given all this, we can now device a strategy to work around all these immensely helpful, well
  # documented and useful tools by looking at each incoming argument, escaping any ' characters
  # with a '"'"' sequence, surrounding each argument with ', joining them with a space separating
  # them and finally injecting a "" sequence at the beginning and end of the concatenated string.
  # There is another bug (https://bugs.ruby-lang.org/issues/11142) that causes ruby to mangle any
  # "" two-character double quote sequence but since we always emit our strings inside ' except for
  # ' characters, this should be ok.  Just remember that an argument '' should get translated to
  # ''"'"''"'"'' on the command line.  If those intervening empty ''s are not present, the presence
  # of "" will cause ruby to mangle that argument.
  $transformedList = $argList | foreach { "'" + ( $_ -replace "'","'`"'`"'" ) + "'" }
  $fortifiedArgString = '""' + ($transformedList -join ' ') + '""'
  
  # Use the correct embedded ruby path.  We'll be deployed at a path that looks like
  # [C:\opscode or some other prefix]\chef\modules\chef
  $ruby = Join-Path (Get-ScriptDirectory)  "..\..\embedded\bin\ruby.exe"
  $commandPath = Join-Path (Get-ScriptDirectory) "..\..\bin\$command"
  & $ruby $commandPath $fortifiedArgString
}


function chef-apply {
  Run-RubyCommand 'chef-apply' $args
}

function chef-client {
  Run-RubyCommand 'chef-client' $args
}

function chef-service-manager {
  Run-RubyCommand 'chef-service-manager' $args
}

function chef-shell {
  Run-RubyCommand 'chef-shell' $args
}

function chef-solo {
  Run-RubyCommand 'chef-solo' $args
}

function chef-windows-service {
  Run-RubyCommand 'chef-windows-service' $args
}

function knife {
  Run-RubyCommand 'knife' $args
}

Export-ModuleMember -function chef-apply
Export-ModuleMember -function chef-client
Export-ModuleMember -function chef-service-manager
Export-ModuleMember -function chef-shell
Export-ModuleMember -function chef-solo
Export-ModuleMember -function chef-windows-service
Export-ModuleMember -function knife

# To debug this module, uncomment the line below and then run the following.
# Export-ModuleMember -function Run-RubyCommand
# Remove-Module chef
# Import-Module chef
# "puts ARGV" | Out-File C:\opscode\chef\bin\puts_args
# Run-RubyCommand puts_args 'Here' "are" some '"very interesting"' 'arguments[to]' "`"try out`""