#!/bin/bash
# uses "/root/tmp/dd.txt" as a temporary file!
for cipher in aes128-cbc aes128-ctr aes128-gcm@openssh.com aes192-cbc aes192-ctr aes256-cbc aes256-ctr aes256-gcm@openssh.com arcfour arcfour128 arcfour256 blowfish-cbc cast128-cbc chacha20-poly1305@openssh.com 3des-cbc ; do
    for i in 1 2 3 ; do
        echo
        echo "Cipher: $cipher (try $i)"

        dd if=/dev/zero bs=1024k count=1024 2>/tmp/dd.txt | pv --size 1G | time -p ssh -o 'Compression=no' -c "$cipher" localhost 'cat > /dev/null'
        grep -v records /tmp/dd.txt
    done
done
