#!/bin/bash
#########################################################################
# Title:         Shitbox Repo Cloner Script                             #
# Author(s):     desimaniac, salty                                      #
# URL:           https://github.com/shaboigan/sb                        #
# --                                                                    #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

################################
# Variables
################################

VERBOSE=false
BRANCH='main'
SHITBOX_PATH="/srv/git/shitbox"
SHITBOX_REPO="https://github.com/shaboigan/shitbox.git"

################################
# Functions
################################

usage () {
    echo "Usage:"
    echo "    sb_repo -b <branch>    Repo branch to use. Default is 'master'."
    echo "    sb_repo -v             Enable Verbose Mode."
    echo "    sb_repo -h             Display this help message."
}

################################
# Argument Parser
################################

while getopts ':b:vh' f; do
    case $f in
    b)  BRANCH=$OPTARG;;
    v)  VERBOSE=true;;
    h)
        usage
        exit 0
        ;;
    \?)
        echo "Invalid Option: -$OPTARG" 1>&2
        echo ""
        usage
        exit 1
        ;;
    esac
done

################################
# Main
################################

$VERBOSE || exec &>/dev/null

$VERBOSE && echo "git branch selected: $BRANCH"

## Clone Shitbox and pull latest commit
if [ -d "$SHITBOX_PATH" ]; then
    if [ -d "$SHITBOX_PATH/.git" ]; then
        cd "$SHITBOX_PATH" || exit
        git fetch --all --prune
        # shellcheck disable=SC2086
        git checkout -f $BRANCH
        # shellcheck disable=SC2086
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
    else
        cd "$SHITBOX_PATH" || exit
        rm -rf library/
        git init
        git remote add origin "$SHITBOX_REPO"
        git fetch --all --prune
        # shellcheck disable=SC2086
        git branch $BRANCH origin/$BRANCH
        # shellcheck disable=SC2086
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
    fi
else
    # shellcheck disable=SC2086
    git clone -b $BRANCH "$SHITBOX_REPO" "$SHITBOX_PATH"
    cd "$SHITBOX_PATH" || exit
    git submodule update --init --recursive
    $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
fi

## Copy settings and config files into Shitbox folder
shopt -s nullglob
for i in "$SHITBOX_PATH"/defaults/*.default; do
    if [ ! -f "$SHITBOX_PATH/$(basename "${i%.*}")" ]; then
        cp -n "${i}" "$SHITBOX_PATH/$(basename "${i%.*}")"
    fi
done
shopt -u nullglob

## Activate Git Hooks
cd "$SHITBOX_PATH" || exit
bash "$SHITBOX_PATH"/bin/git/init-hooks
