FROM docker:dind as builder 

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
	&& apk update

RUN apk add git gcc make cmake musl-dev linux-headers

FROM builder as vpcs

RUN git clone --depth 1 https://github.com/gns3/vpcs

WORKDIR /vpcs/src

RUN sed -i "/#include <sys\/ioctl\.h>/i#include <sys/types.h>" remote.c

RUN ./mk.sh

RUN install vpcs /usr/local/bin/

FROM alpine

COPY --from=vpcs /usr/local/bin/vpcs /usr/local/bin/
