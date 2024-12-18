#!/bin/bash

# This shell script tries to build a debian package starting from the source code. Eventually,
# this script will be part of some pipeline that is part of CI. It should be possible to execute
# this script stand-alone. Some of the following assumptions are made (which in our case are
# totally reasonable) -
# 1. The script exists inside a 'git' repository.
# 2. In the 'git' repository, there is a plan file 'habitat/plan.sh' present, which defines
#    several variables `pkg_*` variables, that we intend to use.
# 3. The environment this file runs has a working `hab` installation. Which means this script
#    will run inside `Linux` on `x86_64` as of Aug 2024. This will change in future.
# 4. The user running the script has 'sudo' permissions.

set -o  pipefail
# TODO: Remove after testing
set -x

# Get the path to the 'plan.sh' file, we are going to be using certain values defined in 'plan' file
TOPLEVEL_DIR=$(git rev-parse --show-toplevel)
HABITAT_DIR=$(if [ -z ${TOPLEVEL_DIR} ]; then echo "" ; else echo "${TOPLEVEL_DIR}/habitat"; fi)
PLAN_FILE_PATH=$(if [ -z ${HABITAT_DIR} ]; then echo ""; else echo "${HABITAT_DIR}/plan.sh"; fi)

# Handy Paths
PACKAGER_SH_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))

HAB_RESULTS_DIR=${TOPLEVEL_DIR}/results

ARCH=$(dpkg --print-architecture)

DEB_STAGING_DIR=$(mktemp -d -t deb-build-$$-XXXX)
# Ordinarily we would take this from the ${pkg_origin}-${pkg_name} (when set - that is after
# `build`), however previous versions of this deb package used a different name - we will just
# reuse that name.
DEB_PKG_NAME=chef

DEB_PKG_DIR=
HAB_EXPORT_TAR_GZ_NAME=
ENV_FILE_NAME=

TS_FILENAME=$(date +%Y%m%d-%H%M.log)
LOG_FILE=results/logs/deb-pkg-build-$$-${TS_FILENAME}

# Prepares the directory structure required for building the Debian package inside the
# ${DEB_STAGING_DIR}.
# 1. Prepares ane exports the file-name (This will be name of the directoy.) for the debian package.
#    (DEB_PKG_NAME)
# 2. Generates the directory structure as follows
#     DEB_PKG_DIR=${DEB_STAGING_DIR}/${DEB_PKG_NAME}
#     DEB_CONTROL_DIR=${DEB_PKG_DIR}/DEBIAN
prepare_deb() {
	local pkgname=${DEB_PKG_NAME:-${pkg_name}}

	export DEB_PKG_NAME_VERSION=${pkgname}-${pkg_version}-${ARCH}
	export DEB_PKG_DIR=${DEB_STAGING_DIR}/${DEB_PKG_NAME_VERSION}
	export DEB_CONTROL_DIR=${DEB_PKG_DIR}/DEBIAN
	export PKG_SCRIPTS_DIR=$(realpath ${PACKAGER_SH_DIR}/../package-scripts/$pkgname)

	mkdir -p ${DEB_CONTROL_DIR}

}

extract_tar_archive() {
	[ -n ${HAB_EXPORT_TAR_GZ_NAME} -o -n ${DEB_PKG_DIR} ]  || \
		err_exit "Some of the environment variables not set or missing."

	tar -C ${DEB_PKG_DIR} -xzpf ${HAB_EXPORT_TAR_GZ_NAME}

	echo "Extracted the Package to ${HAB_PKG_DIR}."
}

# Usage: prepare_control_file <staging-dir> as parameters
# TODO: Add license
# These variables are exported thanks to our `source results/last_build.env`
prepare_control_file() {

	[ -n ${DEB_CONTROL_DIR} ]  || \
		err_exit "Some of the environment variables not set or missing."

	cat << EOF >> ${DEB_CONTROL_DIR}/control
Package: $DEB_PKG_NAME
Architecture: $ARCH
Description: Chef Infra Client
Maintainer: The Chef Maintainers <maintainers@chef.io>
Version: $pkg_version
EOF

	echo "Wrote Debian Control File."
}

# Prepares the `/etc/profile.d/z90-chef.sh` file.
#
# Also writes `/usr/share/$DEB_PKG_NAME/.hab_pkg_install_path file
# TODO: Licenses
prepare_conffiles() {

	local env_dir=${DEB_PKG_DIR}/etc/profile.d
	local env_file_name=z90-${pkg_name}.sh
	local env_file_path=${env_dir}/${env_file_name}

	local hab_pkg_env=$(echo $(hab pkg env $pkg_ident))

	mkdir -p ${env_dir}

	echo "env_file_path: ${env_file_path}"

	cat << EOF > ${env_file_path}
# File installed by  ${DEB_PKG_NAME_VERSION}.deb package
# DO NOT EDIT by hand unless you know what you are doing.

# Save existing PATH and GEM_PATH
PREV_PATH=$PATH
PREV_GEM_PATH=$GEM_PATH

# Following environment variables are exported by package ${pkg_ident}
EOF

	hab pkg env ${pkg_ident} >> ${env_file_path}

	cat << EOF >> ${env_file_path}

# We make sure existing PATH and GEM_PATH are also available.
export PATH=\$PATH:\$PREV_PATH
export GEM_PATH=\$GEM_PATH:\$PREV_GEM_PATH

EOF
	# Mark env file as executable.
	chmod 755 ${env_file_path}

	# Now some package data. This will be used by maintainer scripts.
	# TODO : Add License and other information here.

	local pkg_data_dir=${DEB_PKG_DIR}/usr/share/${DEB_PKG_NAME}/
	local pkg_hab_install_path=$(hab pkg path ${pkg_ident})

	mkdir -p ${pkg_data_dir}

	cat << EOF > ${pkg_data_dir}/.hab_pkg_install_path
${pkg_hab_install_path}
EOF

}

prepare_maintainer_scripts() {
	# We are expecting maintainer scripts in the ../package-scripts/ directory.
	# Reasonable assumption, because this is from our code.

	for f in `ls $PKG_SCRIPTS_DIR/*`; do
		echo "Copying '$(basename $f)' to ${DEB_CONTROL_DIR}.";
		cp $f ${DEB_CONTROL_DIR}
	done
}

run_dpkg_deb_pkg_cmd() {
	echo "Running `dpkg-deb` command to build package: ${DEB_PKG_NAME_VERSION}."
	dpkg-deb --root-owner-group  --build ${DEB_PKG_DIR} ${DEB_PKG_NAME_VERSION}.deb
}

ensure_hab_exists() {

	hab --version

	[ $? -eq 0 ] || err_exit "Habitat Cli `hab` is required to be installed for running this script"
}

# usage: err_exit [<message>] [<exit-code>]
err_exit() {
	ERR_MSG=${1:-"Unknown Error Occured"}
	>&2 echo "Error: ${1}"

	perform_cleanup >/dev/null 2>&1

	ERR_CODE=${2:-1}

	exit ${ERR_CODE}
}

build_and_install_hab_pkg() {
	echo "Building Habitat P ackage from: ${TOPLEVEL_DIR}"
	sudo -E hab origin key generate chef
	sudo -E hab pkg build -k chef -s ${TOPLEVEL_DIR} . | tee ${LOG_FILE} 2>&1

	[ $? -eq 0 ] || err_exit "Error Building the habitat package from ${PLAN_FILE_PATH}."

	# All the `pkg_*` environment variable values are available if our package was successfully built
	# from the following line. Let's export those for the rest of the script.
	source ${HAB_RESULTS_DIR}/last_build.env
	echo "Built Package ${pkg_ident}"

	echo "Installing Package ${pkg_artifact}"
	#hab origin key download ${pkg_origin}

	sudo -E hab pkg install ${HAB_RESULTS_DIR}/${pkg_artifact} | tee ${LOG_FILE} 2>&1

	[ $? -eq 0 ] || err_exit "Error installing the package ${pkg_artifact}."

	echo "Installed Package ${pkg_artifact}."
}

export_hab_pkg_tar() {
	echo "Exporting the built habitat package ${pkg_ident} to tar file."

	# TODO We don't need to set these environmnet variables, remove before submitting the PR
	HAB_ORIGIN=chef HAB_PKG_EXPORT_TAR_BINARY=/bin/hab-pkg-export-tar sudo -E hab pkg export tar ${HAB_RESULTS_DIR}/${pkg_artifact} | tee ${LOG_FILE} 2>&1
	[ $? -eq 0 ] || err_exit "Error while exporting package: '${pkg_artifact}' to tar format."

	export HAB_EXPORT_TAR_GZ_NAME=${pkg_origin}-${pkg_name}-${pkg_version}-${pkg_release}.tar.gz
}

perform_cleanup() {
	echo "Uninstalling the installed hab package ${pkg_ident}."

	sudo -E hab pkg uninstall ${pkg_ident} 2>/dev/null

	# rm -rf ${DEB_STAGING_DIR}
}

build_debian_package() {
	# The following functions perform all the heavylifting using `hab`
	ensure_hab_exists
	build_and_install_hab_pkg
	export_hab_pkg_tar

	# Following commands perform setup for preparing the `deb` archive.
	prepare_deb

	extract_tar_archive

	prepare_control_file
	prepare_conffiles
	prepare_maintainer_scripts

	# Run actual deb command
	run_dpkg_deb_pkg_cmd

	# Cleanup our staging area and any installed `hab` packages.
	perform_cleanup
}

build_debian_package

