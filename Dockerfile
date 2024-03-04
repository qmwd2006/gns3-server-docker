FROM docker:dind as builder 

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
	&& apk update

RUN apk add git gcc make cmake musl-dev linux-headers


FROM builder as vpcs

RUN git clone --depth 1 https://github.com/gns3/vpcs

WORKDIR /vpcs/src

RUN sed -i "/#include <sys\/ioctl\.h>/i#include <sys/types.h>" remote.c

RUN ./mk.sh && install vpcs /usr/local/bin/


FROM builder as ubridge

RUN git clone --depth 1 https://github.com/gns3/ubridge

WORKDIR /ubridge

RUN apk add libpcap-dev libcap-setcap

RUN make && make install


FROM builder as dynamips

RUN git clone --depth 1 https://github.com/gns3/dynamips

WORKDIR /dynamips

RUN apk add elfutils-dev

RUN mkdir build && cd build && cmake .. && make && make install


FROM alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
	&& apk update

RUN apk add libpcap libelf

COPY --from=vpcs /usr/local/bin/vpcs /usr/local/bin/
COPY --from=ubridge /usr/local/bin/ubridge /usr/local/bin/
COPY --from=dynamips /usr/local/bin/dynamips /usr/local/bin/

