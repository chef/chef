_This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes._

# Chef Client Release Notes 12.17:

## Highlighted enhancements for this release:

- Added msu_package resource and provider which supports the installation of Microsoft Update(MSU) packages on Windows. Example:

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

- Alias `unmount` to `umount` for mount resource
Example:

  ```ruby
  mount '/mount/tmp' do
    action :unmount
  end
  ```

- You can now pass multiple nodes/clients to knife node delete or knife client delete operations.

  ```bash
  knife client delete client1,client2,client3
  ```

## Highlighted bug fixes for this release:
