#!/bin/bash
pv --help
for hmac in hmac-sha1 hmac-md5 hmac-sha1-96 hmac-md5-96 hmac-ripemd160 hmac-ripemd160@openssh.com hmac-sha2-256 hmac-sha2-512 hmac-sha2-256-96 hmac-sha2-512-96 none; do
    for i in 1 2 3 ; do
      echo "$hmac $i"
      dd if=/dev/zero bs=1024k count=1024 2>/dev/null | pv --size 1G | ssh -q -x -o "MACs=$hmac" -o 'Compression=no' -o 'StrictHostKeyChecking=no' -c "aes256-ctr" localhost 'cat > /dev/null'
    done
done
