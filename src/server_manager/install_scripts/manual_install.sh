#!/bin/bash

# Install Docker
curl https://get.docker.com/ | sh

# Login into the private DO container registry using Sergey's token.
DO_PAT="<replace by the digital ocean PAT>" && docker login -u "${DO_PAT}" -p "${DO_PAT}" registry.digitalocean.com

# Install outline server
export SB_IMAGE="registry.digitalocean.com/othersidevpn-outline-server/outline_server:latest"
export SB_PUBLIC_IP="64.225.92.65"
curl -sSL https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh | bash

# CONGRATULATIONS! Your Outline server is up and running.

# To manage your Outline server, please copy the following line (including curly
# brackets) into Step 2 of the Outline Manager interface:

# {"apiUrl":"https://64.225.92.65:64653/RQiJF1PbAct89Cr-hOpzJg","certSha256":"C92CE168A31737488B576D52BC43DBBD22347695497A16578360D8585080D337"}

# If you have connection problems, it may be that your router or cloud provider
# blocks inbound connections, even though your machine seems to allow them.

# Make sure to open the following ports on your firewall, router or cloud provider:
# - Management port 64653, for TCP
# - Access key port 1189, for TCP and UDP

# Configure the firewall
apt-get install ufw
ufw disable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 64653/tcp
ufw allow 1189/tcp
ufw allow 1189/udp
ufw allow proto tcp from 164.92.74.3 to any port 9090
ufw allow proto tcp from 164.92.74.3 to any port 9091
ufw allow proto tcp from 164.92.74.3 to any port 9092
ufw enable


############################
## Run with the new image ##
############################

###### On a local machine

# Build new image
cd ~/projects/otherside_vpn/outline-server || exit
npm run action shadowbox/docker/build
docker tag outline/shadowbox registry.digitalocean.com/othersidevpn-outline-server/outline_server
docker push registry.digitalocean.com/othersidevpn-outline-server/outline_server

###### On a remote machine

DO_PAT="<replace by the digital ocean PAT>" && docker login -u "${DO_PAT}" -p "${DO_PAT}" registry.digitalocean.com

# Pull new image
docker pull registry.digitalocean.com/othersidevpn-outline-server/outline_server:latest

# Get the list of environment variables from
#
# "SB_CERTIFICATE_FILE=/opt/outline/persisted-state/shadowbox-selfsigned.crt",
# "SB_PRIVATE_KEY_FILE=/opt/outline/persisted-state/shadowbox-selfsigned.key",
# "SB_METRICS_URL=",
# "SB_DEFAULT_SERVER_NAME=",
# "SB_STATE_DIR=/opt/outline/persisted-state",
# "SB_API_PORT=64653",
# "SB_API_PREFIX=RQiJF1PbAct89Cr-hOpzJg",
# "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
# "NODE_VERSION=18.18.0",
# "YARN_VERSION=1.22.19"
docker inspect shadowbox

# Stop and remove the previous container
docker container stop shadowbox
docker container rm shadowbox

# Run a new one
docker run -d \
  --name "shadowbox" --restart always --net host \
  --label 'com.centurylinklabs.watchtower.enable=true' \
  -v "/opt/outline/persisted-state:/opt/outline/persisted-state" \
  -e "SB_STATE_DIR=/opt/outline/persisted-state" \
  -e "SB_API_PORT=35323" \
  -e "SB_API_PREFIX=MWi4eaR6N2Tpd2ztxrw4cw" \
  -e "SB_CERTIFICATE_FILE=/opt/outline/persisted-state/shadowbox-selfsigned.crt" \
  -e "SB_PRIVATE_KEY_FILE=/opt/outline/persisted-state/shadowbox-selfsigned.key" \
  -e "SB_METRICS_URL=" \
  -e "SB_DEFAULT_SERVER_NAME=" \
  registry.digitalocean.com/othersidevpn-outline-server/outline_server:latest