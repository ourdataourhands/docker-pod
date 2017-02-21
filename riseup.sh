#!/bin/bash
docker_version=$(docker -v)
infinit_user=$(more /mnt/storage/username)
odoh_capacity=$(more /mnt/storage/capacity)
[[ -z "$docker_version" ]] && { echo "Docker does not seem to be installed and in your path."; exit 1; }
[[ -z "$infinit_user" ]] && { echo "ODOH grid user missing."; exit 1; }
[[ -z "$odoh_capacity" ]] && { echo "ODOH storage node capacity missing."; exit 1; }
# Purge
if [[ $1 == "purge" ]] || [[ $2 == "purge" ]]
then
	echo "============================================"
	echo "ODOH: Stop and remove all Docker containers"
	docker stop "$(docker ps -a -q)"
	docker rm "$(docker ps -a -q)"
	echo "###"
	echo
	echo "============================================"
	echo "ODOH: Docker prune system"
	docker system prune -f
	echo "###"
	echo
fi

# x86 or ARM
if [[ $1 == "arm" ]]
then
	# Docker image ARM
	cp -f Dockerfile-arm Dockerfile
	docker_image="odoh-docker-arm"
else
	# Default to x86
	cp -f Dockerfile-x86 Dockerfile
	docker_image="odoh-docker-x86"
fi


echo "============================================"
echo "ODOH: Build image"
docker build --tag=$docker_image . 
echo "###"
echo

echo "============================================"
echo "ODOH: Start image"
docker run -it -d \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_ADMIN \
	--device=/dev/net/tun \
	-v /mnt/storage/zerotier-one:/var/lib/zerotier-one \
	-v /mnt/storage/.local:/root/.local \
	-v /mnt/storage/logs:/root/logs \
	--name $docker_image $docker_image /bin/bash
echo "###"
echo

docker exec -itd $docker_image /root/pod-setup.sh $infinit_user $odoh_capacity

echo "============================================"
echo "ODOH: Finish image"
echo "ODOH: Pod setup started"
echo "###"
echo