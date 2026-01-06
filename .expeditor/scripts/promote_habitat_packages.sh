#!/bin/bash
set -e

PKG_ORIGIN="chef"
PKG_NAME="chef"

echo "Promoting ${PKG_ORIGIN}/${PKG_NAME} to the 'current' channel..."

# This assumes packages were built in the build group context
hab pkg promote "${PKG_ORIGIN}/${PKG_NAME}" "*" current

echo "Promotion done."
