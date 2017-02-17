docker build --tag=odoh:docker-x86 . 
docker run -it -d --rm \
	--cap-add=NET_ADMIN \
	--cap-add=SYS_ADMIN \
	--device=/dev/net/tun \
	-v /mnt/storage/zerotier-one:/var/lib/zerotier-one \
	-v /mnt/storage/.local:/root/.local \
	--name odoh-docker-x86 odoh:docker-x86 /bin/bash
docker exec -itd odoh-docker-x86 /usr/sbin/zerotier-one -d
docker exec -it odoh-docker-x86 /usr/sbin/zerotier-cli join 8056c2e21c000001
# mount the volume