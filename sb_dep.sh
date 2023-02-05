#!/bin/bash
#################################################################################
# Title:         Shitbox: Dependencies Installer                                #
# Author(s):     L3uddz, Desimaniac, EnorMOZ, salty                             #
# URL:           https://github.com/shaboigan/sb                                 #
# Description:   Installs dependencies needed for Shitbox.                      #
# --                                                                            #
#################################################################################
#                     GNU General Public License v3.0                           #
#################################################################################

################################
# Privilege Escalation
################################

# Restart script in SUDO
# https://unix.stackexchange.com/a/28793

if [ "$EUID" != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

################################
# Variables
################################

VERBOSE=true

readonly SYSCTL_PATH="/etc/sysctl.conf"
readonly PYTHON_CMD_SUFFIX="-m pip install \
                              --timeout=360 \
                              --no-cache-dir \
                              --disable-pip-version-check \
                              --upgrade"
readonly PYTHON3_CMD="/srv/ansible/venv/bin/python3 $PYTHON_CMD_SUFFIX"
readonly ANSIBLE=">=7.0.0,<8.0.0"

################################
# Argument Parser
################################

# shellcheck disable=SC2220
while getopts 'v' f; do
    case $f in
    v)	VERBOSE=true;;
    esac
done

################################
# Main
################################

$VERBOSE || exec &>/dev/null

## Disable IPv6
if [ -f "$SYSCTL_PATH" ]; then
    ## Remove 'Disable IPv6' entries from sysctl
    sed -i -e '/^net.ipv6.conf.all.disable_ipv6/d' "$SYSCTL_PATH"
    sed -i -e '/^net.ipv6.conf.default.disable_ipv6/d' "$SYSCTL_PATH"
    sed -i -e '/^net.ipv6.conf.lo.disable_ipv6/d' "$SYSCTL_PATH"
    sysctl -p
fi

## Environmental Variables
export DEBIAN_FRONTEND=noninteractive

## Install Pre-Dependencies
apt-get install -y \
    software-properties-common \
    apt-transport-https
apt-get update

## Add apt repos
add-apt-repository main
add-apt-repository universe
add-apt-repository restricted
add-apt-repository multiverse
apt-get update

## Install apt Dependencies
apt-get install -y \
    nano \
    git \
    curl \
    gpg-agent \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-testresources \
    python3-apt \
    python3-virtualenv \
    python3-venv

## Enforce en_US.UTF-8
locale-gen en_US.UTF-8
update-locale
export LC_ALL=en_US.UTF-8
echo "locale was set to en_US.UTF-8"

cd /srv/ansible || exit

# Check for supported Ubuntu Releases
release=$(lsb_release -cs)

if [[ $release =~ (focal)$ ]]; then
    echo "Focal, deploying venv with Python3.10."
    add-apt-repository ppa:deadsnakes/ppa --yes
    apt install python3.10 python3.10-dev python3.10-distutils python3.10-venv -y
    add-apt-repository ppa:deadsnakes/ppa -r --yes
    rm -rf /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-focal.list
    rm -rf /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-focal.list.save
    python3.10 -m ensurepip
    python3.10 -m venv venv

elif [[ $release =~ (jammy)$ ]]; then
    echo "Jammy, deploying venv with Python3."
    python3 -m venv venv
else
    echo "Unsupported Distro, exiting."
    exit 1
fi

## Install pip3
cd /tmp || exit
curl -sLO https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

## Install pip3 Dependencies
$PYTHON3_CMD \
    pip setuptools wheel
$PYTHON3_CMD \
    pyOpenSSL requests netaddr \
    jmespath jinja2 docker \
    ruamel.yaml tld argon2_cffi \
    ndg-httpsclient dnspython lxml \
    jmespath passlib PyMySQL \
    ansible$ANSIBLE

cp /srv/ansible/venv/bin/ansible* /usr/local/bin/

## Copy /usr/local/bin/pip to /usr/bin/pip
[ -f /usr/local/bin/pip3 ] && cp /usr/local/bin/pip3 /usr/bin/pip3
