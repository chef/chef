<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

## Doc changes for Chef 12.13

### `msu_package` resource

`msu_package` resource is used for installation and removal of Microsoft Update(MSU) packages on Windows.

Example:
```ruby
msu_package 'Install Windows 2012R2 Update KB2959977' do
  source 'C:\Users\xyz\AppData\Local\Temp\Windows8.1-KB2959977-x64.msu'
  action :install
end

msu_package 'Remove Windows 2012R2 Update KB2959977' do
  source 'C:\Users\xyz\AppData\Local\Temp\Windows8.1-KB2959977-x64.msu'
  action :remove
end

# Using URL in source
msu_package 'Install Windows 2012R2 Update KB2959977' do
  source 'https://s3.amazonaws.com/my_bucket/Windows8.1-KB2959977-x64.msu'
  action :install
end

msu_package 'Remove Windows 2012R2 Update KB2959977' do
  source 'https://s3.amazonaws.com/my_bucket/Windows8.1-KB2959977-x64.msu'
  action :remove
end
```
