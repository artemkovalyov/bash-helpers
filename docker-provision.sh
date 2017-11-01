#!/bin/bash
### BEGIN INFO
# Provides:          Provisioning of docker containers for TrueHata Server
# Short-Description: Monitors webhooks from hub.docker.com, downloads containers and runs them.
# Description:       Provides a part of infrastructure for automated builds and delivery
#
### END INFO


set -ex

CPWD=`pwd`

LOG="/var/log/nginx/docker.log"
PREVIOUS_REQUEST_STORE="$CPWD/latest-request"
PREVIOUS_REQUEST=""
LAST_LOGGED=""
DOCKER="docker"
SUBNET_NAME="truehata_net"

#If no path specified (e.g. MOUNT_FOLDER="") app will mount its DB and Data to truehata/ in the root directory
MOUNT_FOLDER=""

[ -x $DOCKER ] && { echo "Docker is not found. Did you forget to install it?"; exit 1; }

remove_containers(){
  # Remove all stoped containers from registry
  docker ps -a -q | xargs docker rm || true
}

stop_containers(){
  $DOCKER stop truehata_app || true
  $DOCKER stop truehata_db || true
  remove_containers

  [ -z "$($DOCKER ps -a | grep -E 'truehata_db|truehata_app')" ] && echo "All containers are stoped and removed"

}

pull_containers(){
  $DOCKER login -u "artemkovalyov" -p "D7E_Si='Sog_g*c/Q\a]%:Q"
  $DOCKER pull passtor/truehata
  $DOCKER pull postgres:9.6-alpine
}

remove_networks(){
  # Remove all unused networks
  docker network prune -f
}

create_network(){
  docker network ls | grep "${SUBNET_NAME}" || docker network create -d bridge --subnet 172.21.0.0/16 ${SUBNET_NAME}
}

run_app(){
  docker run -itd --name=truehata_app \
    --volume ${MOUNT_FOLDER}/truehata:/truehata:rw \
    --network=${SUBNET_NAME} -p 8080:8080 passtor/truehata
}

run_db(){
  docker run --rm -itd --name=truehata_db \
  --volume ${MOUNT_FOLDER}/truehata_db:/var/lib/postgresql/data:rw \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -e POSTGRES_DB=th \
  -e POSTGRES_PASSWORD=some_strong_password \
  --network=truehata_net \
  postgres:9.6-alpine

}

notify_operations(){
  sendEmail -f "notification@metra.org.ua" -t "artem.kovalyov@gmail.com, popov.ua@gmail.com"\
    -u "Latest docker containers were successfully provisioned" -m "TrueHata APP and TrueHata DB are up and running. Do what ever is supposed to do now.\n $($DOCKER ps -a)" \
    -s "smtp.gmail.com" \
    -o "tls=yes" \
    -xu "notification@metra.org.ua" -xp "!!!!!!!change to the PWD!!!!!!!"
}

# Runs all the steps of Docker deployment
provision_docker(){
  pull_containers
  echo "#####stopping containters#####"
  stop_containers
  echo "#####removing networks#####"
  remove_networks
  echo "#####creating network####"
  create_network
  echo "#####run db container#####"
  run_db
  echo "#####run app container#####"
  run_app

  [ -z "$($DOCKER ps -a | grep -E 'truehata_db')" ] || echo "DB is UP"
  [ -z "$($DOCKER ps -a | grep -E 'truehata_app')" ] || echo "APP is UP"
  #TODO check if API is up and running
  #TODO check if DB is up and running
  notify_operations

}



if [[ "$EUID" -ne 0 ]]; then echo "Please run as root"
  exit 1
fi

[ -s "$PREVIOUS_REQUEST_STORE" ] && PREVIOUS_REQUEST=`cat $PREVIOUS_REQUEST_STORE`

# Check for log presence
if [ -s "$LOG" ]; then
  LAST_LOGGED=`tail -1 $LOG`
elif [ -s "$LOG.1" ]; then
  LAST_LOGGED=`tail -1 $LOG.1`
else
  echo "All logs are empty. Run provisioning manually"
  exit 1
fi

if [[ "$PREVIOUS_REQUEST" != "$LAST_LOGGED" ]]; then
          provision_docker
          echo $LAST_LOGGED > $PREVIOUS_REQUEST_STORE
else
  echo "There are no new builds available"
fi
