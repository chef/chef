#!/bin/bash

set -evx


if [ "${ENABLE_ADDON_CHEF_MANAGE:-true}" = 'true' ]; then
    echo -e '\nBEGIN INSTALL CHEF MANAGE ADDON\n'

    sudo chef-server-ctl install chef-manage
    sudo chef-server-ctl reconfigure --chef-license=accept
    sleep 30
    sudo chef-manage-ctl reconfigure --accept-license
    sleep 30

    echo -e '\nEND INSTALL CHEF MANAGE ADDON\n'
else
    echo -e '\n**SKIP** INSTALL CHEF MANAGE ADDON **SKIP**\n'
fi
