<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### value_for_platform Method

- where <code>"platform"</code> can be a comma-separated list, each specifying a platform, such as Red Hat, openSUSE, or Fedora, <code>version</code> specifies the version of that platform, and <code>value</code> specifies the value that will be used if the node's platform matches the <code>value_for_platform</code> method. If each value only has a single platform, then the syntax is like the following:
+ where <code>platform</code> can be a comma-separated list, each specifying a platform, such as Red Hat, openSUSE, or Fedora, <code>version</code> specifies either the exact version of that platform, or a constraint to match the platform's version against. The following rules apply to constraint matches:

+ *  Exact matches take precedence no matter what, and should never throw exceptions.
+ *  Matching multiple constraints raises a <code>RuntimeError</code>.
+ *  The following constraints are allowed: <code><,<=,>,>=,~></code>.
+
+ The following is an example of using the method with constraints:
+
+ ```ruby
+ value_for_platform(
+   "os1" => {
+     "< 1.0" => "less than 1.0",
+     "~> 2.0" => "version 2.x",
+     ">= 3.0" => "version 3.0",
+     "3.0.1" => "3.0.1 will always use this value" }
+ )
+ ```

+ If each value only has a single platform, then the syntax is like the following:

### environment attribute to git provider

Similar to other environment options:

```
environment     Hash of environment variables in the form of {"ENV_VARIABLE" => "VALUE"}.
```

Also the `user` attribute should mention the setting of the HOME env var:

```
user      The system user that is responsible for the checked-out code.  The HOME environment variable will automatically be
set to the home directory of this user when using this option.
```

### Metadata `name` Attribute is Required.

Current documentation states:

> The name of the cookbook. This field is inferred unless specified.

This is no longer correct as of 12.0. The `name` field is required; if
it is not specified, an error will be raised if it is not specified.

### chef-zero port ranges

- to avoid crashes, by default, Chef will now scan a port range and take the first available port from 8889-9999.
- to change this behavior, you can pass --chef-zero-port=PORT_RANGE (for example, 10,20,30 or 10000-20000) or modify Chef::Config.chef_zero.port to be a po
rt string, an enumerable of ports, or a single port number.

### Encrypted Data Bags Version 3

Encrypted Data Bag version 3 uses [GCM](http://en.wikipedia.org/wiki/Galois/Counter_Mode) internally. Ruby 2 and OpenSSL version 1.0.1 or higher are required to use it.

### New windows_service resource

The windows_service resource inherits from the service resource and has all the same options but adds an action and attribute.

action :configure_startup - sets the startup type on the resource to the value of the `startup_type` attribute
attribute startup_type - the value as a symbol that the startup type should be set to on the service, valid options :automatic, :manual, :disabled

Note that the service resource will also continue to set the startup type to automatic or disabled, respectively, when the enabled or disabled actions are used.

### Fetch encrypted data bag items with dsl method
DSL method `data_bag_item` now takes an optional String parameter `secret`, which is used to interact with encrypted data bag items.
If the data bag item being fetched is encrypted and no `secret` is provided, Chef looks for a secret at `Chef::Config[:encrypted_data_bag_secret]`.
If `secret` is provided, but the data bag item is not encrypted, then a regular data bag item is returned (no decryption is attempted).


### New dsc\_script resource

The `dsc_script` resource for Windows systems that allows cookbook authors to embed [PowerShell Desired
State Configuration](http://technet.microsoft.com/en-us/library/dn249912.aspx)
(DSC) script code or re-use existing DSC script
artifacts in a cookbook. It is similar to other Chef `script` resources like
`powershell_script` in that it allows another language to be used from within
the Chef Domain Specific Language (DSL). 

#### DSC Prerequisites

Use of the `dsc_script` resource requires the following components on a
Windows system:

* **PowerShell version 4.0**, which can be configured on the target system through Chef using the
[PowerShell cookbook](https://supermarket.getchef.com/cookbooks/powershell)
available at [Chef Supermarket](http://supermarket.getchef.com).
* **WinRM** service enabled: The **WinRM** service can be enabled on the
    system by executing the command

    `winrm quickconfig`
    

#### What is DSC?

DSC is described in detail at the [PowerShell DSC site](http://technet.microsoft.com/en-us/library/dn249912.aspx). In summary, DSC is a tool similar to Chef for describing the configuration of a system and enacting the configuration. DSC uses a DSL based on the concept of *resources*, which are conceptually the same as resources in the Chef DSL. Like Chef, DSC is idempotent. Because of these similarities, it natural and useful to be able to use DSC from Chef.

Unlike Chef, DSC's DSL is embedded in the PowerShell language environment; Chef's is embedded in Ruby. DSC is exposed in PowerShell through the `Configuration` language element, which takes a PowerShell script block and other parameters similar to a PowerShell function. Within the script block are instances of resources, very much the way resources in Chef are given within a recipe.

The `dsc_script` resource allows this PowerShell DSC code to be embedded within a Chef recipe.

Many DSC resources are exact analogs of Chef resources (e.g. DSC's
`File` resource); therefore, `dsc_script` is most useful in the context of Chef when it is utilized to manage
resources that are *not* supported directly in Chef, such as DSC's `Archive`
resource which decompresses **.zip** files. Another use case for `dsc_script`
is the use in Chef of already-existing PowerShell DSC scripts that perform
important tasks.

#### `dsc_script` actions

In addition to the standard `:nothing` action, this resource has the following action:

|Action|Description|
|------|-----------|
|`:run`|This is the default action. This action triggers PowerShell DSC components of Windows to configure the system according to the configuration specified in `dsc_script`. |

Note that since all DSC code is idempotent, use of guard expressions is not
required with the `dsc_script` resource to implement idempotence. 

#### `dsc_script` attributes

`dsc_script` honors common Chef resource attributes in addition to the following:

|Attribute|Description|
|---------|-----------|
|`code`|This attribute is a `String` that contains PowerShell DSC code for a configuration. If `code` is non-`nil`, it must be set to the value of a PowerShell script block (without enclosing braces) that be passed to a `Configuration` element of the PowerShell DSC DSL. This attribute **MUST NOT** be set to `nil` value if the `command` attribute is to anything other than `nil`. The default value is `nil`.|
|`command`|Path to a .ps1 file containing PowerShell DSC script code with which to configure the node. This file must be capable of being executed as a script outside of Chef to generate a valid DSC configuration according to DSC documentation. This attribute **MUST NOT** be set `nil` if the `code` attribute is set non-`nil`. The default value is `nil`.|
|`configuration_name`|This attribute is a `String` used to specify the name given to a `Configuration` element in the script code specified by `command` that identifies the configuration to apply. It **MUST NOT** be specified if `code` is non-`nil`. If `command` is specified and `configuration_name` is `nil`, then the configuration to be applied is specified by the `name` attribute.|
|`configuration_data`|Used to specify [PowerShell DSC configuration data](https://supermarket.getchef.com/cookbooks/powershell). The attribute is a `String` that conforms to the [.psd1 format](http://msdn.microsoft.com/en-us/library/dd878337(v=vs.85).aspx). It **MUST** specify a node with a name of `localhost` to be used with the `dsc_script` resource|
|`configuration_data_script`| This attribute is a `string` that is a path to a `.psd1` file that **MUST** contain a node named `localhost` to be used with `dsc_script`.|
|`flags`|This attribute is a `Hash` that contains keys of type `:symbol`. This can be used to pass parameters to the script specified by the `command` attributes for DSC code with a `Configuration` element that takes parameters. The value of each key in the hash is the parameter value to pass. This value defaults to `nil` and should not be set if `code` is set -- it is only valid if `command` is non-`nil`.|
|`cwd`|This attribute sets the current working directory of the process that executes the DSC code, which is useful for scripts that rely on the **cwd**. |
|`environment`| This attribute is similar to the `environment` attribute for `script` resources -- it takes keys of type `string` that represent the names of environment variables to set when executing the specified DSC script code. The value of each key is the desired value of each environment variable.|

#### `dsc_script` examples

Here is a recipe fragment with a simple usage of DSC embedded in the Chef
`dsc_script` resource:

```ruby
dsc_script 'emacs' do
  code <<-EOH
  Environment 'texteditor'
  {
    Name = 'EDITOR'
    Value = 'c:\\emacs\\bin\\emacs.exe'
  }
EOH
end
```

The same DSC content could be supplied by specifying a file that contains it
within a PowerShell `Configuration` language element using the `command`
attribute to specify a path to the DSC script file. When using `command`, you
mest either set the `configuration_name` attribute to the value of the argument supplied to `Configuration` in the DSC script, or just set the `dsc_script` resource's `name` attribute to that value, like this:

```ruby
dsc_script `DefaultEditor` do
  command 'c:\dsc_scripts\emacs.ps1'
end
```

which assumes that `c:\dsc_scripts\emacs.ps1` contains a configuration called **DefaultEditor** as in the PowerShell DSC script below:

```powershell
Configuration 'DefaultEditor'  
{
    Environment 'texteditor'
    {
      Name = 'EDITOR'
      Value = 'c:\emacs\bin\emacs.exe'
    }
}
```

##### Using the `configuration_name` attribute

The `configuration_name` attribute may be used to allow the `name` attribute to be set to something other than the configuration in a DSC script. In this example, `configuration_name` is used to select one of the configurations in the DSC script:

```ruby
dsc_script `EDITOR` do
  configuration_name 'vi'
  command 'c:\dsc_scripts\editors.ps1'
end
```

The content of `c:\dsc_scripts\editors.ps1` in this case was:

```powershell
Configuration 'emacs'  
{
    Environment 'TextEditor'
    {
      Name = 'EDITOR'
      Value = 'c:\emacs\bin\emacs.exe'
    }
}

Configuration 'vi'  
{
    Environment 'TextEditor'
    {
      Name = 'EDITOR'
      Value = 'c:\vim\bin\vim.exe'
    }
}
```

##### Passing parameters to DSC configurations

If a DSC script specified with the `command` attribute has a configuration that takes parameters, those may be passed using the `flags` attribute:

```ruby
dsc_script `DefaultEditor` do
  flags { :EditorChoice => 'emacs', :EditorFlags => '--maximized' }
  command 'c:\dsc_scripts\editors.ps1'
end
```

This could be used with the following PowerShell DSC script content for `c:\dsc_scripts\editors.ps1`

```powershell
$choices = @{'emacs' = 'c:\emacs\bin\emacs';'vi' = 'c:\vim\vim.exe';'powershell' = 'powershell_ise.exe'}
Configuration 'DefaultEditor' 
{
    [CmdletBinding()]
    param
    (
        $EditorChoice,
        $EditorFlags = ''
    )
    Environment 'TextEditor'
    {
        Name = 'EDITOR'
        Value =  "$($choices[$EditorChoice]) $EditorFlags"
    }
}
```

##### Using configuration data

DSC's [configuration data](http://technet.microsoft.com/en-us/library/dn249925.aspx)
feature allows further customization of DSC scripts. In some cases, such as
setting behavior for Powershell credential data types, its use in a DSC
configuration is required. The configuration data supplied **MUST** contain an
entry for a node name of `localhost` to be applied by `dsc_script`. 

Configuration data may be supplied directly through the `configuration_data` attribute
of `dsc_script` or the `configuration_data_script` or by specifying the path
to a **.psd1** with the same contents that could be supplied to `configuration_data`.

The following example demonstrates DSC's `User` resource using DSC configuration
data to create a user using a plaintext specification of a password:

```ruby
dsc_script 'BackupUser' do
  configuration_data <<-EOH
@{
AllNodes = @(
             @{
             NodeName = "localhost";
             PSDscAllowPlainTextPassword = $true
             })
}
EOH
  code <<-EOH
$user = 'backup'
$password = ConvertTo-SecureString -String "YourPass$(random)" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $password

User $user
{
    UserName = $user
    Password = $cred
    Description = 'Backup operator'
    Ensure = "Present"
    Disabled = $false
    PasswordNeverExpires = $true
    PasswordChangeRequired = $false
}
EOH

configuration_data <<-EOH
@{
AllNodes = @(
             @{
             NodeName = "localhost";
             PSDscAllowPlainTextPassword = $true
             })
}
EOH
end
```

##### Using `dsc_script` with other Chef resources
Like any other resource in Chef, `dsc_script` can be used in concert with
other Chef resources -- here's an example that downloads a file using Chef's
`remote_file` resource and uncompresses it using DSC's `Archive` resource via
`dsc_script` into a target directory:

```ruby
remote_file "#{Chef::Config[:file_cache_path]}\\DSCResourceKit620082014.zip" do
  source 'http://gallery.technet.microsoft.com/DSC-Resource-Kit-All-c449312d/file/124481/1/DSC%20Resource%20Kit%20Wave%206%2008282014.zip'
end
  
dsc_script 'get-dsc-resource-kit' do
  code <<-EOH
Archive reskit
{
    ensure = 'Present'
    path = "#{Chef::Config[:file_cache_path]}\\DSCResourceKit620082014.zip"
    destination = "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules"
}
EOH
end
```
