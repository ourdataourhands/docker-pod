#!/bin/bash
# Logging
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>~/riseup.log 2>&1

# Log the start
dt="$(date)"
echo "Start $dt"

docker_version="$(docker -v)"
infinit_user="$(cat /mnt/storage/root/username)"
odoh_capacity="$(cat /mnt/storage/root/capacity)"

if [[ -z "$docker_version" ]]; then
	echo "Docker does not seem to be installed and in your path."
	exit 1
else
	echo "Found: $docker_version"
fi

if [[ -z "$infinit_user" ]]; then
	echo "ODOH username missing."
	exit 1
else
	echo "ODOH username: $infinit_user"
fi

if [[ -z "$odoh_capacity" ]]; then
	echo "ODOH storage node capacity missing."
	exit 1
else
	echo "ODOH capacity: $odoh_capacity"
fi

# Purge
if [[ $1 == "purge" ]] || [[ $2 == "purge" ]]; then
	echo "============================================"
	echo "ODOH: Stop and remove all Docker containers"
	sudo docker stop "$(docker ps -a -q)"
	sudo docker rm "$(docker ps -a -q)"
	echo "###"
	echo
	echo "============================================"
	echo "ODOH: Docker prune system"
	sudo docker system prune -f
	echo "###"
	echo
fi

# Architecture
arch="$(uname -m)"

case $arch in
	'armv6l')
		echo "ARMV6L! WISE UP, EYES UP, RISE UP!"
		# Docker image ARM v6
		cp -f Dockerfile-armv6l Dockerfile
		docker_image="odoh-docker-armv6l"
		;;
	'armv7l')
		echo "ARMV7L! WISE UP, EYES UP, RISE UP!"
		# Docker image ARM v7
		cp -f Dockerfile-armv7l Dockerfile
		docker_image="odoh-docker-armv7l"
		;;
	'x86_64')
		echo "X86_64! WISE UP, EYES UP, RISE UP!"
		# Default to x86
		cp -f Dockerfile-x86_64 Dockerfile
		docker_image="odoh-docker-x86_64"
		;;
	*)
		echo "X86! WISE UP, EYES UP, RISE UP!"
		# Default to x86
		cp -f Dockerfile-x86 Dockerfile
		docker_image="odoh-docker-x86"
		;;
esac

echo "============================================"
echo "ODOH: Build image"
curl -s http://sh.ourdataourhands.org/beacon.sh | bash -s docker-build
docker build --tag=$docker_image . 
echo "###"
echo

echo "============================================"
echo "ODOH: Start image"
curl -s http://sh.ourdataourhands.org/beacon.sh | bash -s docker-run-image
docker run -it -d \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_ADMIN \
	--device=/dev/net/tun \
	-v /mnt/storage/zerotier-one:/var/lib/zerotier-one \
	-v /mnt/storage/root:/root \
	--name $docker_image $docker_image /bin/bash
echo "###"
echo

docker exec -itd $docker_image /tmp/pod-setup.sh $infinit_user $odoh_capacity

echo "============================================"
echo "ODOH: Finish image"
echo "ODOH: Pod setup started"
echo "###"
echo