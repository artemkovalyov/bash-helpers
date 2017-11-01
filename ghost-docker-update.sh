#!/bin/bash
### BEGIN INFO
# Provides:          Provisioning of docker containers for Blogs
# Short-Description: Automatically updates and restarts Ghost blog containers
# Description:       Provides a part of infrastructure for automated builds and delivery
#
### END INFO


set -ex

CPWD=`pwd`

DOCKER="docker"

[ -x $DOCKER ] && { echo "Docker is not found. Did you forget to install it?"; exit 1; }

remove_containers(){
  # Remove all stoped containers from registry
  docker ps -a -q | xargs docker rm || true
}

stop_containers(){
  $DOCKER stop ukovalova.com  || true
  $DOCKER stop truehata.com || true
  $DOCKER stop novapromova.com || true
  $DOCKER stop blog.umetra.com || true
  remove_containers

  [ -z "$($DOCKER ps -a | grep -E 'ukovalova.com|truehata.com|novapromova.com|blog.umetra.ocm')" ] && echo "All containers are stoped and removed"

}

pull_containers(){
  $DOCKER pull ghost:alpine
}

run_app(){

$DOCKER run -itd --name ukovalova.com -p 2370:2368 -e url=https://ukovalova.com -v /var/www/blogs/ukovalova.com:/var/lib/ghost/content ghost:alpine
$DOCKER run -itd --name blog.umetra.com -e url=https://blog.umetra.com -p 2368:2368 -v /var/www/blogs/blog.umetra.com:/var/lib/ghost/content ghost:alpine
$DOCKER run -itd --name novapromova.com -e url=https://novapromova.com -p 2369:2368 -v /var/www/blogs/novapromova.com:/var/lib/ghost/content ghost:alpine
$DOCKER run -itd --name truehata.com -e url=https://blog.truehata.com -p 2371:2368 -v /var/www/blogs/truehata.com:/var/lib/ghost/content ghost:alpine
}

notify_operations(){
  sendEmail -f "notification@metra.org.ua" -t "artem.kovalyov@gmail.com"\
    -u "Ghost Docker container was updated" -m "List of Docker containers running.\n $($DOCKER ps -a)" \
    -s "smtp.gmail.com" \
    -o "tls=yes" \
    -xu "notification@metra.org.ua" -xp "!!!!!PWD!!!!!!"
}

# Runs all the steps of Docker deployment
provision_docker(){
  pull_containers
  echo "#####stopping containters#####"
  stop_containers
  echo "#####run app container#####"
  run_app

  [ -z "$($DOCKER ps -a | grep -E 'ukovalova.com')" ] || echo "ukovalova.com is UP"
  [ -z "$($DOCKER ps -a | grep -E 'truehata.com')" ] || echo "truehata.com is UP"
  [ -z "$($DOCKER ps -a | grep -E 'novapromova.com')" ] || echo "novapromova.com is UP"
  [ -z "$($DOCKER ps -a | grep -E 'blog.umetra.com')" ] || echo "blog.umetra.com is UP"

  notify_operations

}


if [[ "$EUID" -ne 0 ]]; then echo "Please run as root"
  exit 1
fi

provision_docker
