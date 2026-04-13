#!/bin/sh
exec 2>&1

export SSL_CERT_FILE="{{pkgPathFor "core/cacerts"}}/ssl/cert.pem"

if [[ -z "{{cfg.config_path}}" ]]; then
  CLIENT_CONFIG="{{pkg.svc_config_path}}"
else
  CLIENT_CONFIG="{{cfg.config_path}}"
fi

if [[ "${CLIENT_CONFIG##*.}" != "rb" ]]; then
  CLIENT_CONFIG=${CLIENT_CONFIG}/client.rb
fi

exec chef-client --fork -c ${CLIENT_CONFIG} --chef-license {{cfg.chef_license}}
