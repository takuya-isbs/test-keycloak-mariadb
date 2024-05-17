PROJECT="testkc"
LXD_IMAGE=ubuntu:22.04
HOST1="${PROJECT}-kc1"
HOSTS="${PROJECT}-kc1 ${PROJECT}-kc2 ${PROJECT}-kc3"
NETWORK_NAME=$PROJECT
PROFILE_NAME=${PROJECT}-prof
LXC=lxc

exec_para() {
    HOSTS="$1"
    shift
    for HOST in $HOSTS; do
	eval "HOST_${HOST}_tmp=\$(mktemp --suffix=${PROJECT}.log)"
	eval "LOG=\${HOST_${HOST}_tmp}"
	$LXC exec $HOST -- "$@" > $LOG 2>&1 &
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
