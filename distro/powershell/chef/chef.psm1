function Run-Command($command, $argList) {
  # Take each input string, escape any \ ' or " character in it and then surround it with "s.
  # This is to defeat the second-level parsing performed by the MSVCRT argument parser used
  # by ruby which only understands \ ' and ".
  #
  # This is a fuster cluck.  Don't touch this unless you are sure you understand regexes.
  # The \\ is to request a literal \ match in a regex.
  # The "" is to inject a literal " character in a PS string surrounded by "s.
  # The replacement pattern must be '\$1' and not "\$1" because $1 is not a real variable
  # that needs substituting - it's a capture group that's interpreted by the regex engine.
  # \ in the replacement pattern does not need to be escaped - it is literally substituted.
  $transformed = $argList | foreach { '"' + ( $_ -replace "([\\'""])",'\$1' ) + '"' }
  #& "echoargs.exe" $transformed
  & "ruby.exe" $command $transformed
}


function chef-apply {
  Run-Command 'chef-apply' $args
}

function chef-client {
  Run-Command 'chef-client' $args
}

function chef-service-manager {
  Run-Command 'chef-service-manager' $args
}

function chef-shell {
  Run-Command 'chef-shell' $args
}

function chef-solo {
  Run-Command 'chef-solo' $args
}

function chef-windows-service {
  Run-Command 'chef-windows-service' $args
}

function knife {
  Run-Command 'knife' $args
}

Export-ModuleMember -function chef-*
Export-ModuleMember -function knife