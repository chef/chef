===================================================================
Deprecation: Cloud plugin replaced by the Cloud_V2 plugin (OHAI-8)
===================================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_cloud.rst>`__

In Ohai/Chef releases 13 we replaced the existing Cloud plugin with the Cloud_v2 plugin. This was done by having the Cloud_v2 plugin populate both ``node['cloud']`` and ``node['cloud_v2']``. The Cloud_v2 plugin includes a different data format that resolves many of the longstanding bugs in the existing Cloud plugin.

Remediation
=============

If you have a cookbook that relies on data from ``node['cloud']`` you will need to update the code to for the new format in Chef 13. On a Chef 12 or ealier node you can compare the data formats by running ``ohai cloud`` and ``ohai cloud_v2``.

Here are examples of the old and new format of the cloud data:

.. code-block:: javascript

  {
    "public_ips": [
      "52.88.253.144"
    ],
    "private_ips": [
      "172.31.37.209"
    ],
    "public_ipv4": "52.88.253.144",
    "public_hostname": "ec2-52-88-253-144.us-west-2.compute.amazonaws.com",
    "local_ipv4": "172.31.37.209",
    "local_hostname": "ip-172-31-37-209.us-west-2.compute.internal",
    "provider": "ec2"
  }


.. code-block:: javascript

  {
    "public_ipv4_addrs": [
      "52.88.253.144"
    ],
    "local_ipv4_addrs": [
      "172.31.37.209"
    ],
    "public_hostname": "ec2-52-88-253-144.us-west-2.compute.amazonaws.com",
    "local_hostname": "ip-172-31-37-209.us-west-2.compute.internal",
    "public_ipv4": "52.88.253.144",
    "local_ipv4": "172.31.37.209",
    "provider": "ec2"
  }
