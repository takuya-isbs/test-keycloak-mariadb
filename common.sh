source ./default.sh
[ -f ./config.sh ] && source ./config.sh

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

set -eu -o pipefail
if [ ${DEBUG:-1} -eq 1 ]; then
    set -x
fi
