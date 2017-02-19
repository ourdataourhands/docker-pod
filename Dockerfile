FROM	ubuntu:16.10
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
	&&	curl -q --output infinit.tbz https://storage.googleapis.com/sh_infinit_releases/linux64/Infinit-x86_64-linux_debian_oldstable-gcc4-0.7.3.tbz \
	&&	tar xjf infinit.tbz --strip-components=1 -C . \
	&&	rm infinit.tbz
COPY 	pod-setup.sh /root/
RUN 	chmod +x /root/pod-setup.sh
RUN 	mkdir -p /root/logs
RUN 	chmod +w /root/logs
ENV		PATH="/opt/infinit/bin:${PATH}"
RUN 	curl -s https://install.zerotier.com/ | /bin/bash
EXPOSE	9993/udp 6379/udp