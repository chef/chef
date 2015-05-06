function chef-client {
  <#  
  .SYNOPSIS
  A chef-client is an agent that runs locally on every node that is under management by Chef.
  .DESCRIPTION
  When a chef-client is run, it will perform all of the steps that are required to bring the node into the expected state, including:

  Registering and authenticating the node with the Chef server
  Building the node object
  Synchronizing cookbooks
  Compiling the resource collection by loading each of the required cookbooks, including recipes, attributes, and all other dependencies
  Taking the appropriate and required actions to configure the node
  Looking for exceptions and notifications, handling each as required
  .EXAMPLE
  chef-client --help
  #>
  [CmdletBinding()]
  param (
    [parameter(ValueFromRemainingArguments=$true)] $All
  )

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
  $Transformed = $All | foreach { '"' + ( $_ -replace "([\\'""])",'\$1' ) + '"' }
  & "ruby.exe" "chef-client" $Transformed
}