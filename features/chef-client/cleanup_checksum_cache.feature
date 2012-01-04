@client @checksum_cache @checksum_cache_cleanup @chef_1397
Feature: Cleanup checksum cache
  In order to not use all of the available inodes on the filesystem with unneeded files
  As a sysadmin
  I want Chef to remove unused checksum cache files

  Scenario: Remove cached file checksums that are no longer needed 
    Given a validated node
      And it includes the recipe 'template'
     When I run the chef-client with '-l info' and the 'client_with_checksum_caching' config
     Then the run should exit '0'
    Given it includes no recipes
     When I run the chef-client with '-l debug' and the 'client_with_checksum_caching' config
     Then the run should exit '0'
      And 'stdout' should have 'Removing unused checksum cache file .*chef\-file\-\-.*\-chef\-rendered\-template.*'

      
# for example:
# DEBUG: removing unused checksum cache file /Users/ddeleo/opscode/chef/features/data/tmp/checksum_cache/chef-file--var-folders-Ui-UiODstTvGJm3edk+EIMyf++++TI--Tmp--chef-rendered-template20100929-40338-1rjvhyc-0