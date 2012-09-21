# Overview
RPMs are now automatically signed for every build.
* RPMs are signed using GPG.
* The GPG key is the same as for apt.opscode.com
* The cannonical store of the GPG key is teampass
* The gpg key is installed by jenkins-support::gpg_key recipe
* rpm tries to force you to use a password, the `sign-rpm` script works
  around this.


# How RPMs Get Signed:
## Extracting GPG Key from gpg Keyring:

    gpg --export  -a 'Opscode Omnibus Esq' > OmnibusGPG

## Importing GPG Key into RPM:

    sudo rpm --import OmnibusGPG

