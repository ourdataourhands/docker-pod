FROM	ubuntu:16.10
ARG 	INFINIT_URL = "https://storage.googleapis.com/sh_infinit_releases/linux64/Infinit-x86_64-linux_debian_oldstable-gcc4-0.7.3.tbz"
ARG		INFINIT_USER = "odoh._user"
ARG		ODOH_CAPACITY = "1GB"
RUN 	apt-get update -y
RUN 	apt-get install -y \
	fuse \
	curl \
	tar \
	bzip2 \
	iputils-ping \
	net-tools
RUN     mkdir -p /opt/infinit \
	&&	cd /opt/infinit \
	&&	curl -q ${INFINIT_URL} --output infinit.tbz\
	&&	tar xjf infinit.tbz --strip-components=1 -C . \
	&&	rm infinit.tbz
ENV	PATH="/opt/infinit/bin:${PATH}"
# RUN  	curl -s https://install.zerotier.com/ | bash
COPY	/mnt/storage/id_rsa* /root/
RUN		infinit user import --key /root/id_rsa \
	&&	infinit user fetch --as ${INFINIT_USER} --name odoh._captain \
	&&	infinit network fetch --as ${INFINIT_USER} \
	&&	infinit volume fetch --as ${INFINIT_USER} \
	&&	infinit passport fetch --as ${INFINIT_USER} \
	&&	infinit silo create --filesystem --capacity ${ODOH_CAPACITY} --name local \
	&&	infinit network link --as ${INFINIT_USER} --name 
EXPOSE	9993/udp 6379/udp
