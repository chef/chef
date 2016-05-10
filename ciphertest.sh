#!/bin/bash
pv --help
for cipher in aes128-cbc 3des-cbc blowfish-cbc cast128-cbc aes192-cbc aes256-cbc rijndael-cbc@lysator.liu.se idea-cbc none arcfour128 arcfour256 arcfour aes128-ctr aes192-ctr aes256-ctr cast128-ctr blowfish-ctr 3des-ctr; do
    for i in 1 2 3 ; do
      echo "$cipher $i"
      dd if=/dev/zero bs=1024k count=1024 2>/dev/null | pv --size 1G | ssh -q -x -o 'Compression=no' -o 'StrictHostKeyChecking=no' -c "$cipher" localhost 'cat > /dev/null'
    done
done
