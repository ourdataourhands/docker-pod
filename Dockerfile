FROM ubuntu:16.10
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y tahoe-lafs
