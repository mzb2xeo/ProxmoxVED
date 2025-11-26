#!/usr/bin/env bash
#source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
source <(curl -fsSL https://raw.githubusercontent.com/mzb2xeo/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.docker.com/

APP="Docker"
var_tags="${var_tags:-docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_keyctl="1" # Enables keyctl() support for Docker for this container

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  msg_info "Updating base system"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Base system updated"

  msg_info "Installing dependencies and adding Docker Repository"
  $STD apt update -y
  $STD apt install -y ca-certificates curl gnupg

  $STD mkdir -p /etc/apt/keyrings
  $STD curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $STD chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  $STD apt update -y
  $STD apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sleep 10
  # Install docker compose v2
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  $STD mkdir -p "$DOCKER_CONFIG"/cli-plugins
  $STD curl -SL https://github.com/docker/compose/releases/download/v2.40.3/docker-compose-linux-x86_64 -o "$DOCKER_CONFIG"/cli-plugins/docker-compose
  $STD chmod +x "$DOCKER_CONFIG"/cli-plugins/docker-compose
  # Wait for Docker Compose to become available, up to 30 seconds
  for i in {1..30}; do
    if docker compose version >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ! docker compose version >/dev/null 2>&1; then
    echo "Error: Docker Compose did not become available after installation." >&2
    $STD docker stop portainer && $STD docker rm portainer
  fi
  docker --version
  docker compose version
  docker-compose --version
  msg_ok "Docker CE cli engine & docker-compose plugin installed"

  if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
    msg_info "Updating Portainer"
    $STD docker pull portainer/portainer-ce:latest
    $STD docker stop portainer && docker rm portainer
    $STD docker volume create portainer_data >/dev/null 2>&1
    $STD docker run -d \
      -p 8000:8000 \
      -p 9443:9443 \
      --name=portainer \
    $STD docker stop portainer_agent && $STD docker rm portainer_agent
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
    msg_ok "Updated Portainer"
  fi
sleep 5
  if docker ps -a --format '{{.Names}}' | grep -q '^portainer_agent$'; then
    msg_info "Updating Portainer Agent"
    $STD docker pull portainer/agent:latest
  # Wait for Portainer Agent to be ready on port 9001 (max 30s)
  for i in {1..30}; do
    if curl -fs http://localhost:9001 > /dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ! curl -fs http://localhost:9001 > /dev/null 2>&1; then
    echo "Warning: Portainer Agent did not become ready after 30 seconds."
  fi
    $STD docker run -d \
      -p 9001:9001 \
      --name=portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      portainer/agent
    msg_ok "Updated Portainer Agent"
  fi
sleep 5
  msg_info "Cleaning up"
  $STD apt-get -y autoremove && $STD apt-get -y autoclean
  msg_ok "Cleanup complete"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description
update_script

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} If you installed Portainer, access it at the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:9443${CL}"
