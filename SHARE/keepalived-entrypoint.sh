#!/bin/sh
set -eu
set -x

# shut up "WARNING - equal priority advert received from remote host with our IP address"
# SEE: https://github.com/osixia/docker-keepalived/issues/33#issuecomment-1436201438

IPV4_ADDRESSES=$(ip addr show $KEEPALIVED_INTERFACE | awk '/inet / {print $2}' | cut -d '/' -f 1)

for ADDRESS in $IPV4_ADDRESSES; do
    export KEEPALIVED_UNICAST_PEERS=$(/usr/bin/python3 <<EOF
import ast, os;
existing_list = ast.literal_eval(os.environ["KEEPALIVED_UNICAST_PEERS"].split(":")[1])
filtered_list = list(filter(lambda x: x != "${ADDRESS}", existing_list))
print("#PYTHON2BASH:" + str(filtered_list))
EOF
)
done

#env

exec /container/tool/run
