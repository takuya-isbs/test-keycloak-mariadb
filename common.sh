PROJECT="testkc"
LXD_IMAGE=ubuntu:22.04
IPADDR_PREFIX=10.60.204
HOST1="${PROJECT}-kc1"
HOSTS="kc1 kc2 kc3 manage"
NETWORK_NAME=$PROJECT
PROFILE_NAME=${PROJECT}-prof
LXC=lxc

lxc_exist() {
    len=$($LXC ls -f compact $1 | wc -l)
    if [ $len -ge 2 ]; then
	return 0  # True
    fi
    return 1  # False
}

exec_para() {
    HOSTS="$1"
    shift
    for HOST in $HOSTS; do
	FULLNAME=${PROJECT}-${HOST}
	eval "HOST_${HOST}_tmp=\$(mktemp --suffix=${PROJECT}.log)"
	eval "LOG=\${HOST_${HOST}_tmp}"
	$LXC exec $FULLNAME -- "$@" > $LOG 2>&1 &
    done
    wait
    for HOST in $HOSTS; do
	eval "LOG=\${HOST_${HOST}_tmp}"
        cat $LOG
	rm -f $LOG
    done
}

set -eu
set -x
