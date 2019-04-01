#!/bin/sh

echo "Starting dionaea...\n"
export PATH=$PATH:/opt/dionaea/bin
dionaea -u nobody -g nogroup -r /opt/dionaea -w /opt/dionaea -p /opt/dionaea/var/dionaea.pid
