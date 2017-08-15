======================================================================
Deprecation: Amazon linux moved to the Amazon platform_family (OHAI-7)
======================================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_amazon_linux.rst>`__

In Ohai/Chef releases prior to 13 Amazon Linux was identified as platform_family 'rhel'. In Ohai/Chef 13 and later Amazon Linux will be identified as the 'amazon' platform_family. When Amazon Linux was created it closely mirrored the structure and package naming of RHEL 5, and with the release of RHEL 6 Amazon Linux moved to closely resemble RHEL 6. With the release of RHEL 7, Redhat switched to the systemd init system, and Amazon Linux has not yet decided to make that same switch. In addition to the init system Amazon Linux has added many critical packages with their own unique naming convention. This makes it very hard for users write cookbooks for the 'rhel' platform_family that will work on Amazon Linux systems out of the box. In order to simplify multi-platform cookbook code and to make it more clear when cookbooks actually support Amazon Linux we've created the 'amazon' platform_family and removed Amazon Linux from the 'rhel' platform_family.

Remediation
=============

If you have a cookbook that relies on platform_family of 'rhel' to support Redhat based distros as well as Amazon Linux you'll need to modify your code to specifically check for the 'amazon' platform_family.

Existing code only checking for rhel platform family:

.. code-block:: ruby

  if platform_family('rhel')
    service 'foo' do
      action :start
    end
  end


Updated code to check for both rhel and amazon platform families:

.. code-block:: ruby

  if platform_family('rhel', 'amazon')
    service 'foo' do
      action :start
    end
  end
