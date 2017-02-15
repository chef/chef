
function Load-Win32Bindings {
  Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace Chef
{

[StructLayout(LayoutKind.Sequential)]
public struct PROCESS_INFORMATION
{
  public IntPtr hProcess;
  public IntPtr hThread;
  public uint dwProcessId;
  public uint dwThreadId;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct STARTUPINFO
{
  public uint cb;
  public string lpReserved;
  public string lpDesktop;
  public string lpTitle;
  public uint dwX;
  public uint dwY;
  public uint dwXSize;
  public uint dwYSize;
  public uint dwXCountChars;
  public uint dwYCountChars;
  public uint dwFillAttribute;
  public STARTF dwFlags;
  public ShowWindow wShowWindow;
  public short cbReserved2;
  public IntPtr lpReserved2;
  public IntPtr hStdInput;
  public IntPtr hStdOutput;
  public IntPtr hStdError;
}

[StructLayout(LayoutKind.Sequential)]
public struct SECURITY_ATTRIBUTES
{
  public int length;
  public IntPtr lpSecurityDescriptor;
  public bool bInheritHandle;
}

[Flags]
public enum CreationFlags : int
{
  NONE = 0,
  DEBUG_PROCESS = 0x00000001,
  DEBUG_ONLY_THIS_PROCESS = 0x00000002,
  CREATE_SUSPENDED = 0x00000004,
  DETACHED_PROCESS = 0x00000008,
  CREATE_NEW_CONSOLE = 0x00000010,
  CREATE_NEW_PROCESS_GROUP = 0x00000200,
  CREATE_UNICODE_ENVIRONMENT = 0x00000400,
  CREATE_SEPARATE_WOW_VDM = 0x00000800,
  CREATE_SHARED_WOW_VDM = 0x00001000,
  CREATE_PROTECTED_PROCESS = 0x00040000,
  EXTENDED_STARTUPINFO_PRESENT = 0x00080000,
  CREATE_BREAKAWAY_FROM_JOB = 0x01000000,
  CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 0x02000000,
  CREATE_DEFAULT_ERROR_MODE = 0x04000000,
  CREATE_NO_WINDOW = 0x08000000,
}

[Flags]
public enum STARTF : uint
{
  STARTF_USESHOWWINDOW = 0x00000001,
  STARTF_USESIZE = 0x00000002,
  STARTF_USEPOSITION = 0x00000004,
  STARTF_USECOUNTCHARS = 0x00000008,
  STARTF_USEFILLATTRIBUTE = 0x00000010,
  STARTF_RUNFULLSCREEN = 0x00000020,  // ignored for non-x86 platforms
  STARTF_FORCEONFEEDBACK = 0x00000040,
  STARTF_FORCEOFFFEEDBACK = 0x00000080,
  STARTF_USESTDHANDLES = 0x00000100,
}

public enum ShowWindow : short
{
    SW_HIDE = 0,
    SW_SHOWNORMAL = 1,
    SW_NORMAL = 1,
    SW_SHOWMINIMIZED = 2,
    SW_SHOWMAXIMIZED = 3,
    SW_MAXIMIZE = 3,
    SW_SHOWNOACTIVATE = 4,
    SW_SHOW = 5,
    SW_MINIMIZE = 6,
    SW_SHOWMINNOACTIVE = 7,
    SW_SHOWNA = 8,
    SW_RESTORE = 9,
    SW_SHOWDEFAULT = 10,
    SW_FORCEMINIMIZE = 11,
    SW_MAX = 11
}

public enum StandardHandle : int
{
  Input = -10,
  Output = -11,
  Error = -12
}

public enum HandleFlags : int
{
  HANDLE_FLAG_INHERIT = 0x00000001,
  HANDLE_FLAG_PROTECT_FROM_CLOSE = 0x00000002
}

public static class Kernel32
{
  [DllImport("kernel32.dll", SetLastError=true)]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool CreateProcess(
    string lpApplicationName,
    string lpCommandLine,
    ref SECURITY_ATTRIBUTES lpProcessAttributes,
    ref SECURITY_ATTRIBUTES lpThreadAttributes,
    [MarshalAs(UnmanagedType.Bool)] bool bInheritHandles,
    CreationFlags dwCreationFlags,
    IntPtr lpEnvironment,
    string lpCurrentDirectory,
    ref STARTUPINFO lpStartupInfo,
    out PROCESS_INFORMATION lpProcessInformation);

  [DllImport("kernel32.dll", SetLastError=true)]
  public static extern IntPtr GetStdHandle(
    StandardHandle nStdHandle);
    
  [DllImport("kernel32.dll")]
  public static extern bool SetHandleInformation(
    IntPtr hObject, 
    int dwMask, 
    uint dwFlags);

  [DllImport("kernel32", SetLastError=true)]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool CloseHandle(
    IntPtr hObject);

  [DllImport("kernel32", SetLastError=true)]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool GetExitCodeProcess(
    IntPtr hProcess,
    out int lpExitCode);
    
  [DllImport("kernel32.dll", SetLastError = true)]
  public static extern bool CreatePipe(
    out IntPtr phReadPipe, 
    out IntPtr phWritePipe, 
    IntPtr lpPipeAttributes, 
    uint nSize);
        
  [DllImport("kernel32.dll", SetLastError = true)]
  public static extern bool ReadFile(
    IntPtr hFile, 
    [Out] byte[] lpBuffer, 
    uint nNumberOfBytesToRead, 
    ref int lpNumberOfBytesRead, 
    IntPtr lpOverlapped);

  [DllImport("kernel32.dll", SetLastError = true)]
  public static extern bool PeekNamedPipe(
    IntPtr handle,
    byte[] buffer, 
    uint nBufferSize, 
    ref uint bytesRead,
    ref uint bytesAvail, 
    ref uint BytesLeftThisMessage);

  public const int STILL_ACTIVE = 259;
}
}
"@
}

function Run-ExecutableAndWait($AppPath, $ArgumentString) {
  # Use the Win32 API to create a new process and wait for it to terminate.
  $null = Load-Win32Bindings

  $si = New-Object Chef.STARTUPINFO
  $pi = New-Object Chef.PROCESS_INFORMATION

  $pSec = New-Object Chef.SECURITY_ATTRIBUTES
  $pSec.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($pSec)
  $pSec.bInheritHandle = $true
  $tSec = New-Object Chef.SECURITY_ATTRIBUTES
  $tSec.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($tSec)
  $tSec.bInheritHandle = $true

  # Create pipe for process stdout
  $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Runtime.InteropServices.Marshal]::SizeOf($si))
  [System.Runtime.InteropServices.Marshal]::StructureToPtr($pSec, $ptr, $true)
  $hReadOut = [IntPtr]::Zero
  $hWriteOut = [IntPtr]::Zero
  $success = [Chef.Kernel32]::CreatePipe([ref] $hReadOut, [ref] $hWriteOut, $ptr, 0)
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to create output pipe.  Error code $reason."
  }
  $success = [Chef.Kernel32]::SetHandleInformation($hReadOut, [Chef.HandleFlags]::HANDLE_FLAG_INHERIT, 0)
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to set output pipe handle information.  Error code $reason."
  }

  $si.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($si)
  $si.wShowWindow = [Chef.ShowWindow]::SW_SHOW
  $si.dwFlags = [Chef.STARTF]::STARTF_USESTDHANDLES
  $si.hStdOutput = $hWriteOut
  $si.hStdError = $hWriteOut
  $si.hStdInput = [Chef.Kernel32]::GetStdHandle([Chef.StandardHandle]::Input)
  
  $success = [Chef.Kernel32]::CreateProcess(
      $AppPath, 
      $ArgumentString, 
      [ref] $pSec, 
      [ref] $tSec, 
      $true, 
      [Chef.CreationFlags]::NONE, 
      [IntPtr]::Zero, 
      $pwd, 
      [ref] $si, 
      [ref] $pi
  )
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to create process [$ArgumentString].  Error code $reason."
  }

  $sb = New-Object System.Text.StringBuilder
  $buffer = New-Object byte[] 1024

  # Initialize reference variables
  $bytesRead = 0
  $bytesAvailable = 0
  $bytesLeftThisMsg = 0
  $global:LASTEXITCODE = [Chef.Kernel32]::STILL_ACTIVE

  $isActive = $true
  while ($isActive) {
    $success = [Chef.Kernel32]::GetExitCodeProcess($pi.hProcess, [ref] $global:LASTEXITCODE)
    if (-Not $success) {
      $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
      throw "Process exit code unavailable.  Error code $reason."
    }

    $success = [Chef.Kernel32]::PeekNamedPipe(
        $hReadOut, 
        $null, 
        $buffer.Length, 
        [ref] $bytesRead, 
        [ref] $bytesAvailable, 
        [ref] $bytesLeftThisMsg
    )
    if (-Not $success) {
      $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
      throw "Output pipe unavailable for peeking.  Error code $reason."
    }

    if ($bytesRead -gt 0) {
      while ([Chef.Kernel32]::ReadFile($hReadOut, $buffer, $buffer.Length, [ref] $bytesRead, 0)) {
        $output = [Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
        if ($output) {
          [void]$sb.Append($output)
        }
        if ($bytesRead -lt $buffer.Length) {
          # Partial buffer indicating the end of stream, break out of ReadFile loop
          # ReadFile will block until:
          #    The number of bytes requested is read.
          #    A write operation completes on the write end of the pipe.
          #    An asynchronous handle is being used and the read is occurring asynchronously.
          #    An error occurs.
          break
        }
      }
    }
    
    if ($global:LASTEXITCODE -ne [Chef.Kernel32]::STILL_ACTIVE) {
      $isActive = $false
    }
  }

  # Return output obtained from child process stdout/stderr
  $sb.ToString()

  # Cleanup handles
  $success = [Chef.Kernel32]::CloseHandle($pi.hProcess)
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to release process handle.  Error code $reason."
  }
  $success = [Chef.Kernel32]::CloseHandle($pi.hThread)
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to release thread handle.  Error code $reason."
  }
  $success = [Chef.Kernel32]::CloseHandle($hWriteOut)
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to release output write handle.  Error code $reason."
  }
  $success = [Chef.Kernel32]::CloseHandle($hReadOut)
  if (-Not $success) {
    $reason = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Unable to release output read handle.  Error code $reason."
  }
  [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
}

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
  # apply.  When using & (call operator) and providing an array of arguments, powershell (verified
  # on PS 4.0 on Windows Server 2012R2) will not evaluate them but (contrary to documentation),
  # it will still marginally interpret them.  The behaviour of PS 5.0 seems to be different but
  # ignore that for now.  If any of the provided arguments has a space in it, powershell checks
  # the first and last character to ensure that they are " characters (and that's all it checks).
  # If they are not, it will blindly surround that argument with " characters.  It won't do this
  # operation if no space is present, even if other special characters are present. If it notices
  # leading and trailing " characters, it won't actually check to see if there are other "
  # characters in the string.  Since PS 5.0 changes this behavior, we could consider using the --%
  # "stop screwing up my arguments" operator, which is available since PS 3.0.  When encountered
  # --% indicates that the rest of line is to be sent literally...  except if the parser encounters
  # %FOO% cmd style environment variables.  Because reasons.  And there is no way to escape the
  # % character in *any* waym shape or form.
  # https://connect.microsoft.com/PowerShell/feedback/details/376207/executing-commands-which-require-quotes-and-variables-is-practically-impossible
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
  # with a '"'"' sequence, surrounding each argument with ' & joining them with a space separating
  # them.
  # There is another bug (https://bugs.ruby-lang.org/issues/11142) that causes ruby to mangle any
  # "" two-character double quote sequence but since we always emit our strings inside ' except for
  # ' characters, this should be ok.  Just remember that an argument '' should get translated to
  # ''"'"''"'"'' on the command line.  If those intervening empty ''s are not present, the presence
  # of "" will cause ruby to mangle that argument.
  $transformedList = $argList | foreach { "'" + ( $_ -replace "'","'`"'`"'" ) + "'" }
  $fortifiedArgString = $transformedList -join ' '

  # Use the correct embedded ruby path.  We'll be deployed at a path that looks like
  # [C:\opscode or some other prefix]\chef\modules\chef
  $ruby = Join-Path (Get-ScriptDirectory)  "..\..\embedded\bin\ruby.exe"
  $commandPath = Join-Path (Get-ScriptDirectory) "..\..\bin\$command"

  Run-ExecutableAndWait $ruby """$ruby"" '$commandPath' $fortifiedArgString"
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
