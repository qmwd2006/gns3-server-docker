FROM docker:dind as base

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
	&& apk update \
	&& apk add alpine-conf \
	&& /sbin/setup-timezone -z Asia/Shanghai \
	&& apk del alpine-conf


FROM base as builder 

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


FROM base as server

RUN apk add python3 gcc python3-dev musl-dev linux-headers

RUN python -m venv /opt/gns3-venv && /opt/gns3-venv/bin/pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir gns3-server


FROM base

ENTRYPOINT ["/sbin/init"]

COPY --from=vpcs /usr/local/bin/vpcs /usr/local/bin/
COPY --from=ubridge /usr/local/bin/ubridge /usr/local/bin/
COPY --from=dynamips /usr/local/bin/dynamips /usr/local/bin/
COPY --from=server /opt/gns3-venv/ /opt/gns3-venv/

RUN apk add --no-cache openrc python3 mtools qemu-img qemu-system-x86_64 iproute2 libpcap libelf busybox-static util-linux-misc \
	busybox-openrc dhcp \
	&& rm -f /var/cache/apk/* \
	&& sed -i '/^tty/s/.*/#\0/' /etc/inittab \
	&& rc-update add syslog boot && rc-update add dhcpd default

ADD ./patch/ /

