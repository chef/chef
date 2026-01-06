$clientDir = "C:\chef"
New-Item -ItemType Directory -Force -Path $clientDir | Out-Null

$content = 'chef_server_url "https://localhost/organizations/test"' + "`n"
$content += 'chef_license "accept"' + "`n"
$content += 'rubygems_url "https://rubygems.org/"' + "`n"
$content += "require 'aws-sdk'"
Set-Content -Path (Join-Path $clientDir 'client.rb') -Value $content -Encoding UTF8

$targetDir = "C:\opscode\chef\embedded\bin"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
$candidates = @("C:\opscode\chef-workstation\embedded\bin\openssl.exe", "D:\opscode\chef-workstation\embedded\bin\openssl.exe")
$openssl = $null
foreach ($cand in $candidates) {
  if (Test-Path $cand) { $openssl = $cand; break }
}
if (-not $openssl) {
  $searchRoot = "C:\opscode"
  if (Test-Path $searchRoot) {
    $found = Get-ChildItem -Path $searchRoot -Recurse -Filter openssl.exe -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match 'embedded\\bin' } | Select-Object -First 1
    if ($found) { $openssl = $found.FullName }
  }
}
if ($openssl) {
  Copy-Item -Path $openssl -Destination (Join-Path $targetDir 'openssl.exe') -Force
  Write-Host "Mapped openssl.exe to $targetDir"
} else {
  Write-Warning "OpenSSL not found"
}

$sslDir = "C:\ssl_test"
New-Item -ItemType Directory -Force -Path $sslDir | Out-Null

$opensslPath = "C:\opscode\chef\embedded\bin\openssl.exe"
if (-not (Test-Path $opensslPath)) {
  Write-Error "openssl.exe not found at $opensslPath"
  exit 1
}

Push-Location $sslDir
& $opensslPath genrsa -out ca.key 2048
& $opensslPath req -x509 -new -nodes -key ca.key -subj "/CN=Test CA" -days 365 -out my_ca.crt
& $opensslPath genrsa -out my_signed_cert.key 2048
& $opensslPath req -new -key my_signed_cert.key -subj "/CN=localhost" -out my_signed_cert.csr
& $opensslPath x509 -req -in my_signed_cert.csr -CA my_ca.crt -CAkey ca.key -CAcreateserial -out my_signed_cert.crt -days 365 -sha256
Pop-Location

$verify = & $opensslPath verify -CAfile "$sslDir\my_ca.crt" "$sslDir\my_signed_cert.crt"
Write-Host "openssl verify output: $verify"
