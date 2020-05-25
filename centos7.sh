#!/usr/bin/env bash

VERSION=1.0.0-beta
VERSION_DOCKER_COMPOSE=1.25.5

# ---
# Install SenLife backend server in CentOS7
# Version $VERSION
# Testing on CentOS 7.6 - DigitalOcean - May 25, 2020
# ---

# Variables
ENABLE_DOCKER=false
ENABLE_VIM=false

# Get options
for i in "$@"
do
  case ${i} in
  --enable-docker=*)
  if [[ ${i#*=} = true ]] || [[ ${i#*=} = 1 ]]; then
    ENABLE_DOCKER=true
  fi
  shift
  ;;
  --enable-vim=*)
  if [[ ${i#*=} = true ]] || [[ ${i#*=} = 1 ]]; then
    ENABLE_VIM=true
  fi
  shift
  ;;
  --version-docker-compose=*)
  if [[ -n ${i#*=} ]]; then
    VERSION_DOCKER_COMPOSE=${i#*=}
  fi
  shift
  ;;
  *)
  ;;
esac
done

# Functions
function isNotInstalled() {
  if yum list installed "$@" >/dev/null 2>&1; then
    false
  else
    true
  fi
}

function isLineNotExists() {
  if [ ! -z $(grep "$1" $2) ]; then
    false
  else
    true
  fi
}

function installDocker() {
  # Uninstall old version
  yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

  # Install Docker CE
  yum install -y yum-utils
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io
  systemctl start docker
  systemctl enable docker

  # Install Docker Compose
  if [[ ! -e /usr/local/bin/docker-compose ]]; then
    curl -L "https://github.com/docker/compose/releases/download/${VERSION_DOCKER_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi
}

function installVim() {
  echo -e "---\n\- Installing NeoVim...\n"
  if isNotInstalled neovim; then
    yum install -y neovim python3-neovim
  fi
  echo -e "\n- Installed successfully.\n---\n"
}

function fixEnvironment() {
  # FIX: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory
  if isLineNotExists "LANG=en_US.utf-8" /etc/environment; then
    echo "LANG=en_US.utf-8" >> /etc/environment
    echo "LC_ALL=en_US.utf-8" >> /etc/environment
  fi

  # Set Time-zone
  timedatectl set-timezone Asia/Ho_Chi_Minh
}

# Install epel-release
if isNotInstalled epel-release; then
  yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
fi

# Update YUM mirror cache & YUM Packages
yum update -y

# Install GIT
if isNotInstalled git; then
  yum install -y git
fi

# Install Docker
if [[ $ENABLE_DOCKER = true ]]; then
  installDocker
fi

# Install Vim
if [[ $ENABLE_VIM = true ]]; then
  installVim
fi

# Fix environment
fixEnvironment