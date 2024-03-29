#!/bin/bash
# This script used to install softwares on Ubuntu 18.04 
# Please DO NOT run it on other OS
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/Eronana/ubuntu-setup/master/setup.sh)
#   bash <(curl -sL https://raw.githubusercontent.com/Eronana/ubuntu-setup/master/setup.sh) tools zsh node ...

NODE_MAJOR=20
ZSH_CONFIG_INSTALL_DIR=/opt
TOOLS=(
  git
  screen
  htop
  # language-pack-zh-hans
)
NODE_TOOLS=(
  http-server
  tldr
)

function in_array {
  local e
  for e in ${@:2}; do 
    [[ $e == $1 ]] && return 0; 
  done
  return 1
}

function list_array {
  local e
  for e in $@; do 
    echo -e "\033[36m$e\033[0m"
  done
}

function install {
  if [[ $EUID -ne 0 ]]; then
    echo -e "\033[31mThis script must be run as root.\033[0m"
    exit 1
  fi

  local installs=`declare -F | grep install_ | sed 's/^declare -f install_//'`
  local list=${@-${installs[@]}}
  local toInstalls=()
  local options=()
  local name

  for name in $list; do
    if [[ $name == -* ]]; then
      options+=(`echo $name | cut -c 2-`)
    elif ! in_array $name ${installs[@]}; then
      echo -e "\033[31mIgnored invalid item: \033[33m$name\033[0m"
    else
      toInstalls+=($name)
    fi
  done

  if [ ${#options[@]} -ne 0 ]; then
    toInstalls=()
    for name in ${installs[@]}; do
      if ! in_array $name ${options[@]}; then
        toInstalls+=($name)
      fi
    done
  fi

  local total=${#toInstalls[@]}
  local count=0
  if [ $total -eq 0 ]; then
    echo -e "\033[31mNo valid install item, available item:\033[0m"
    echo -e "\033[36m${installs[*]}\033[0m"
    exit 1
  fi

  echo "The following items will be installed:"
  list_array ${toInstalls[@]}
  read -p "Continue (Y/n)?" CONT
  echo
  if [[ ! $CONT =~ ^[Yy]?$ ]]
  then
    exit 1
  fi

  for name in ${toInstalls[@]}; do
    count=$((count + 1))
    echo -e "\033[32m========[Installing $name($count/$total)]========\033[0m"
    $"install_"${name}
    if [[ $? -ne 0 ]]; then
      echo -e "\033[31mFailed to install \033[33m$name\033[0m"
    fi
  done
  echo -e "\033[32mDone.\033[0m"
}

function install_tools {
  echo "The following Ubuntu packages will be installed:"
  list_array ${TOOLS[@]} 
  apt install -y ${TOOLS[*]} 
}

function install_docker {
  sudo apt-get update
  sudo apt-get install ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  
  # Add the repository to Apt sources:
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

function install_zsh {
  apt install -y zsh autojump python3-dev python3-pip python3-setuptools &&
  pip3 install thefuck &&
  pushd $ZSH_CONFIG_INSTALL_DIR > /dev/null &&
  git clone https://github.com/eronana/zsh-config.git &&
  cd zsh-config &&
  touch zshrc.zwc &&
  chmod a+w zshrc.zwc &&
  echo "source $(pwd)/zshrc.linux" >> ~/.zshrc &&
  chsh -s $(which zsh) &&
  popd > /dev/null
}

function install_node {
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install nodejs -y
}

function install_node_tools {
  echo "The following node packages will be installed:"
  list_array ${NODE_TOOLS[@]} 
  npm i -g  ${NODE_TOOLS[*]} 
}

install $*

