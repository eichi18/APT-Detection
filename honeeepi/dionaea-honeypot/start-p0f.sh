#!/bin/sh
p0f -i any -u root -Q /tmp/p0f.sock -q -l -d -o /dev/null -c 1024
chown nobody:nogroup /tmp/p0f.sock
