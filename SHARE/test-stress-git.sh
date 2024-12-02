#!/bin/bash
set -eu
set -x

NUM_TEST=10

TESTDIR="$1"
[ -e "$TESTDIR" ] && exit 1

BAREDIR="${TESTDIR}/repo"
SYNC_TODIR="${TESTDIR}/repo-sync"
WORKDIR1="${TESTDIR}/work1"
WORKDIR2="${TESTDIR}/work2"
WORKDIR3="${TESTDIR}/work3"

POST_RECEIVE=hooks/post-receive

test_init() {
    git init --bare "$BAREDIR"
    cd "$BAREDIR"
    git config --global init.defaultBranch main

    cat <<EOF > $POST_RECEIVE
#!/bin/sh
set -eu
set -x
#while read oldrev newrev refname; do
#done

#sleep 2
rsync -av --delete "${BAREDIR}/" "${SYNC_TODIR}/"
false
EOF
    chmod +x $POST_RECEIVE
}

test_init

test_clone() {
    set -eu
    local DIR="$1"
    git clone "$BAREDIR" "$DIR"
    cd "$DIR"
    git config --local user.name "Your Name $DIR"
    git config --local user.email you@example.com

    echo "$DIR" >> README.md
    git add README.md
    git commit -m "$DIR" README.md
    git push
}

test_clone "$WORKDIR1"
test_clone "$WORKDIR2"
test_clone "$WORKDIR3"

update_commit() {
    set -eu
    local MGS="$1"
    openssl rand -base64 10 > testfile
    git add testfile
    git commit -m "$MSG" testfile
}

test_commitpush() {
    set -eu
    local DIR="$1"
    local MSG="$2"
    cd "$DIR"
    while :; do
	update_commit "$MSG"
	if git push; then
	    git log -n 2
	    break
	fi
	git reset --hard HEAD^
	git diff HEAD
	git pull --ff-only
	git log -n 2
    done
}

test_commit_para() {
    for i in $(seq $NUM_TEST); do
	test_commitpush "$WORKDIR1" "${i} @process1" &
	test_commitpush "$WORKDIR2" "${i} @process2" &
	test_commitpush "$WORKDIR3" "${i} @process3" &
	wait
    done
}

test_commit_para

diff -r "${BAREDIR}/" "${SYNC_TODIR}/"

echo "DONE"
