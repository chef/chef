===========================================================
Deprecation: DigitalOcean plugin attribute changes (OHAI-6)
===========================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_digitalocean.rst>`__

Ohai's previous Digital Ocean plugin relied on hint data passed to Ohai as well and the drop's internal network interface configuration. The Digital Ocean plugin has been rewritten to poll information from the Digital Ocean Metadata endpoint instead. This provides additional Digital Ocean specific droplet configuration information as well as external IP address information that was previously not available. With the addition of new network configuration data, the format has changed and users relying on the previous format will need to update their cookbooks.

Remediation
=============

Update cookbooks to use the new network data format as seen below.

Example of previous data format:

.. code-block:: json

  {
    "networks": {
      "v4": [
        {
          "ip_address": "138.68.99.253",
          "type": "public",
          "netmask": "255.255.240.0"
        },
        {
          "ip_address": "10.19.0.5",
          "type": "private",
          "netmask": "255.255.0.0"
        }
      ],
      "v6": [
        {
          "ip_address": "2a03:b0c0:0003:00d0:0000:0000:322a:3001",
          "type": "public",
          "cidr": "128"
        },
        {
          "ip_address": "fe80:0000:0000:0000:d4b1:9eff:fe61:8cce",
          "type": "private",
          "cidr": "128"
        }
      ]
    }
  }


Example of new data format:

.. code-block:: json

  {
    "droplet_id": 12345678,
    "hostname": "mytestnode",
    "public_keys": [
      "ssh-rsa SOMEKEY",
    ],
    "auth_key": "SOMEKEY",
    "region": "fra1",
    "interfaces": {
      "public": [
        {
          "ipv4": {
            "ip_address": "138.68.99.253",
            "netmask": "255.255.240.0",
            "gateway": "138.68.96.1"
          },
          "ipv6": {
            "ip_address": "2A03:B0C0:0003:00D0:0000:0000:322A:3001",
            "cidr": 64,
            "gateway": "2A03:B0C0:0003:00D0:0000:0000:0000:0001"
          },
          "anchor_ipv4": {
            "ip_address": "10.19.0.5",
            "netmask": "255.255.0.0",
            "gateway": "10.19.0.1"
          },
          "mac": "d6:b1:9e:61:8c:ce",
          "type": "public"
        }
      ]
    },
    "floating_ip": {
      "ipv4": {
        "active": false
      }
    },
    "dns": {
      "nameservers": [
        "2001:4860:4860::8844",
        "2001:4860:4860::8888",
        "8.8.8.8"
      ]
    },
    "tags": null
  }

As an example where you would previously use the attribute ``node['digital_ocean']['networks']['v4'][0]['ipaddress']`` you would now use ``node['digital_ocean']['interfaces']['public'][0]['ipv4']['ip_address']``.
