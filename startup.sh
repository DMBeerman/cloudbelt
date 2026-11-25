#!/bin/sh
set -eu -o pipefail

PACKAGES="iputils-ping
jq
less
lsb-release
nano
nmap
screen"

grab_thirdparty_pubkeys() {
    ## Prepare APT keyring directory.
    mkdir --parents /etc/apt/keyrings

    ## Grab Microsoft's pubkey.
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
        gpg --dearmor >/etc/apt/keyrings/microsoft.gpg
    chmod go+r /etc/apt/keyrings/microsoft.gpg

    ## Grab Confluent's pubkey.
    curl -sLS https://packages.confluent.io/confluent-cli/deb/archive.key |
        gpg --dearmor >/etc/apt/keyrings/confluent-cli.gpg
    chmod go+r /etc/apt/keyrings/confluent-cli.gpg
}

configure_thirdparty_repos() {
    #AZ_DIST=$(lsb_release -cs)
    # Temporary workaround for missing support for Trixie (13).
    AZ_DIST=bookworm
    ## Configure Azure CLI repo.
    echo \
"Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: $AZ_DIST
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" \
        >/etc/apt/sources.list.d/azure-cli.sources

    ## Configure Confluent CLI repo.
    echo "deb [signed-by=/etc/apt/keyrings/confluent-cli.gpg] https://packages.confluent.io/confluent-cli/deb stable main" \
        >/etc/apt/sources.list.d/confluent-cli.list
}

install_py_packages() {
    pip install confluent-kafka
}

run_main() {
    ## Update main repo and install basic packages.
    apt update
    apt -y upgrade
    apt -y install $PACKAGES
    apt autoremove

    ## Update third-party repo(s) and install their utilities.
    grab_thirdparty_pubkeys
    configure_thirdparty_repos
    apt update
    apt -y install \
        azure-cli  \
        confluent-cli

    ## Clean out local repo cache.
    apt clean

    install_py_packages
}

run_main
