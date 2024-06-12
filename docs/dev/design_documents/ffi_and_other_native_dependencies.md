# FFI and Other Native Dependencies 

![FFI graph](ffi_graph.png)

# `chef` org gems
## `chef-powershell` gem

Subdirectories of [chef-powershell-shim](https://github.com/chef/chef-powershell-shim) project that ultimately defines the gem:
* `chef-powershell` is the ruby code that defines the gem
* `Chef.PowerShell` is a C# wrapper for the .NET version of PowerShell 
* `Chef.PowerShell.Core` is a C# wrapper for the .NET Core version of PowerShell (`pwsh`)
* `Chef.PowerShell.Wrapper` is a C++ Wrapper for `Chef.PowerShell` and the code that `ffi` attaches to from Ruby for PowerShell
* `Chef.PowerShell.Wrapper.Core` is a C++ Wrapper for `Chef.PowerShell.Core` and the code that `ffi` attaches to from Ruby for PowerShell Core

Dependencies
* PowerShell install
* .NET (>= 4.0) or .NET Core
* `ffi-yajl` to parse the 

## `ffi-libarchive` gem

## `ffi-yajl` gem

## `ffi-win32-extensions` gem

# External dependencies of the above

## `libarchive` library

## `ffi` gem

## `yajl` library

```text
@startmindmap
* chef
** chef-powershell
*** ffi/ffi (external, native gem) 
*** C++ -> C# shim
**** Windows native powershell DLLs
** ffi-libarchive gem
*** ffi/ffi (external, native gem) 
*** (external dynamic library, defined by omnibus-software) libarchive/libarchive 
** ffi-yajl gem
*** libyajl2-gem gem
**** (external) lloyd/yajl
*** ffi/ffi (external, native gem) 
** ffi-win32-extensions gem
*** ffi/ffi (external, native gem) 
@endmindmap
```