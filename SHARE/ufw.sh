#!/bin/bash
set -eu
set -x
source ./lib-node.sh

DELETE="${1:-}"

if [ "$DELETE" != delete ]; then
    DELETE=""
fi

# LXD network = 10.0.0.0/8
# REFERENCE: ufw-docker: https://github.com/chaifeng/ufw-docker
AFTER=/etc/ufw/after.rules
cp_backup_restore $AFTER

if [ "$DELETE" != delete ]; then
    cat <<EOF >> $AFTER

# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:ufw-docker-logging-deny - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j ufw-user-forward

### これを許可すると LXDネットワーク同じなので常に通過してしまう
# (一般ホストネットワークなら、これら行をコメントアウトしても良い)
#-A DOCKER-USER -j RETURN -s 10.0.0.0/8

### これを許可しないと Docker コンテナ内から他の LXD ホストと通信できない
-A DOCKER-USER -j RETURN -s 172.16.0.0/12

### 不要に見える
# (一般ホストネットワークなら、これら行をコメントアウトしても良い)
#-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN

# これら定義がないと、Docker で公開したポートは ufw が効かず素通りする
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN

-A ufw-docker-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW DOCKER BLOCK] "
-A ufw-docker-logging-deny -j DROP

COMMIT
# END UFW AND DOCKER
EOF
fi

ufw reload

# 参考: ufw-docker kc-mariadb-1 を実行した際に発行されるコマンドの一部
#ufw route allow proto tcp from 10.60.204.101 to 172.19.0.2 port 4567 comment "allow kc-mariadb-1 4567/tcp kc_mynet"
# MEMO: ufw-docker コマンドは、接続元IPアドレスを許可できないため、以下のようにした

# 各ノード用通信はそのアドレスのみを許可
for ip in $(read_listfile ./ipaddr-list.txt); do
    # Docker で公開したポートはこれで許可
    ufw route $DELETE allow proto tcp from $ip to any
    ufw route $DELETE allow proto udp from $ip to any
    ufw route $DELETE allow proto vrrp from $ip to any
    # それ以外のポートはこれで許可
    ufw $DELETE allow proto tcp from $ip to any
    ufw $DELETE allow proto udp from $ip to any
    ufw $DELETE allow proto vrrp from $ip to any
done

# Docker のネットワークからホストのアドレスへ許可
# /etc/docker/daemon.json の default-address-pools
# または docker-compose.yml の subnet と同じ範囲
DOCKER_IP_RANGE=172.30.0.0/16
ufw $DELETE allow proto tcp from $DOCKER_IP_RANGE to any

# http はどこからでも許可
ufw route $DELETE allow proto tcp from any to any port 443
ufw $DELETE allow proto tcp from any to any port 443

ufw enable
ufw status verbose
