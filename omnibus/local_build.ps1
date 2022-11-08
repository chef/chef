# omnibus/omnibus.rb looking for x64 or x86 or defaults to x86
$env:MSYSTEM="UCRT64"
$ENV:MSYS2_INSTALL_DIR="C:/Ruby31-x64/msys64"
$env:OMNIBUS_WINDOWS_ARCH = "x64"
$env:OMNIBUS_FIPS_MODE="true"
$mePath=$env:PATH
$env:PATH="C:\Program Files\7-Zip;C:\Ruby31-x64\msys64\usr\bin;C:\Ruby31-x64\msys64\ucrt64\bin;$env:MSYS2_INSTALL_DIR\usr\bin;C:\Program Files\git\bin;$mePath"

$env:OMNIBUS_GITHUB_BRANCH="tp/debug-fips-locally"
$env:OMNIBUS_SOFTARE_GITHUB_BRANCH="tp/debug-fips-locally"

bundle config set --local without development
bundle update --conservative omnibus
bundle update --conservative omnibus-software
bundle install
pushd ..
bundle install
popd
mkdir $env:MSYS2_INSTALL_DIR\tmp
bundle exec omnibus build chef
