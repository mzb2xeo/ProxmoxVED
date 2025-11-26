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


# Optionally set variables, e.g.:
# DOCKER_PORTAINER="true"
# DOCKER_LOG_DRIVER="json-file"


start
build_container
description
wait 20
source <(curl -fsSL https://raw.githubusercontent.com/mzb2xeo/ProxmoxVED/main/misc/tools.func)
setup_docker


msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} If you installed Portainer, access it at the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:9443${CL}"
