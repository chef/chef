*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see [https://docs.chef.io/release_notes.html](https://docs.chef.io/release_notes.html) for the official Chef release notes.*

# Chef Client Release Notes 12.16:

## Highlighted enhancements for this release:

* Added powershell_package resource and provider which supports installation of packages through Powershell Package Manager

  ```ruby
  powershell_package 'xCertificate' do
    action :install
    version "1.1.0.0"
  end

  powershell_package 'Install Multiple Packages' do
    action :install
    package_name ['xCertificate','xNetworking']
    version ["2.0.0.0","2.12.0.0"]
  end

  powershell_package 'Install Multiple Packages' do
    action :install
    package_name ['xCertificate','xNetworking']
    version [nil,"2.12.0.0"]
  end

  powershell_package 'Install Multiple Packages' do
    action :install
    package_name ['xCertificate','xNetworking']
  end

  powershell_package ['xCertificate','xNetworking'] do
    action :remove
    version ["2.0.0.0","2.12.0.0"]
  end

  powershell_package 'xCertificate' do
    action :remove
  end
  ```

For using powershell_package resource, Administrative access is required and source needs to be already added in Powershell Package Manager using `Register-PackageSource` command

* Added `attribute_changed` event hook:

In a cookbook library file, you can add this in order to print out all attribute changes in cookbooks:

```ruby
Chef.event_handler do
  on :attribute_changed do |precedence, key, value|
    puts "setting attribute #{precedence}#{key.map {|n| "[\"#{n}\"]" }.join} = #{value}"
  end
end
```

If you want to setup a policy that override attributes should never be used:

```ruby
Chef.event_handler do
  on :attribute_changed do |precedence, key, value|
    raise "override policy violation" if precedence == :override
  end
end
```

There will likely be some missed attribute changes and some bugs that need fixing (hint: PRs accepted), there could be
added command line options to print out all attribute changes or filter them (hint: PRs accepted), or to add source
file and line numbers to the event (hint: PRs accepted).

## Highlighted bug fixes for this release:

