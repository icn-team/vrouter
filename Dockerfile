FROM ubuntu:18.04

# Build hicn suite (from source for disabling punting)

WORKDIR /hicn

# sysrepo plugin
#ENV HICN_SYSREPO_DEB=hicn-extra-plugin_19.08-6-release_amd64.deb
#ENV HICN_SYSREPO_URL=https://logs.fd.io/production/vex-yul-rot-jenkins-1/hicn-merge-master-ubuntu1804/278/archives/scripts/build/${HICN_SYSREPO_DEB}

ARG DEBIAN_FRONTEND=noninteractive

# Use bash shell
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get update && apt-get install -y curl
RUN curl -s https://packagecloud.io/install/repositories/fdio/release/script.deb.sh | bash
RUN apt-get -y update


# Install VPP
RUN apt-get install -y vpp libvppinfra vpp-plugin-core vpp-dev vpp-plugin-dpdk libparc libparc-dev python3-ply python python-ply 

# Install utils for hiperf
RUN  apt-get update && apt-get install -y iproute2 net-tools ethtool ifstat

# Install main packages
RUN apt-get install -y git cmake build-essential libpcre3-dev swig dh-autoreconf xz-utils \
    libprotobuf-c-dev libev-dev libavl-dev protobuf-c-compiler libssl-dev \
    libssh-dev libcurl4-openssl-dev libasio-dev --no-install-recommends openssh-server dumb-init \
    && apt-get update  \
    && apt-get install -y autoconf automake libtool make libreadline-dev texinfo \
    pkg-config libpam0g-dev libjson-c-dev bison flex python3-pytest \
    libc-ares-dev python3-dev libsystemd-dev python-ipaddress python3-sphinx \
    install-info libsnmp-dev perl libnuma-dev linux-headers-$(uname -r) lshw pciutils tcpdump vim iputils-ping \
  ###############################################                                               \
  # Build libyang from source                                                                   \
  ################################################                                              \
  && git clone https://github.com/CESNET/libyang                                                \
  && mkdir -p libyang/build                                                                     \
  && pushd libyang/build && cmake -DENABLE_LYD_PRIV=ON -D CMAKE_BUILD_TYPE:String="Release" -DCMAKE_INSTALL_PREFIX=/usr .. && make -j 4 install && popd   \
  ##############################################                                                 \
  #  Install hicn router  and hicn plugin                                                        \
  ##############################################                                                 \
  && apt-get install hicn-extra-plugin                                                           \
  && apt-get install hicn-plugin                                                                  \
  ################################################                                          \
  #  Install hicn sysrepo plugin                                                                 \
  ###############################################                                               \
#  && curl -OL ${HICN_SYSREPO_URL}                                                             \
#  && apt-get install -y ./${HICN_SYSREPO_DEB}                                                  \
  ###################################################                                           \
  # Install FRR                                                                                 \
  ###################################################                                           \
  && git clone https://github.com/FRRouting/frr.git                                             \
  && cd frr                                                                                     \
  && git checkout stable/7.1                                                                    \
  && ./bootstrap.sh                                                                             \
  && ./configure  --prefix=/usr  --enable-exampledir=/usr/share/doc/frr/examples/               \
  --localstatedir=/var/run/frr  --sbindir=/usr/lib/frr                                          \
  --sysconfdir=/etc/frr    --enable-systemd=yes                                                 \
  --enable-pimd   --enable-watchfrr                                                             \
  && make &&  make install                                                                      \
  ####################################################                                          \
  #   Configure FRR                                                                             \
  ####################################################                                          \
  && groupadd -r -g 92 frr                                                                      \
  && groupadd -r -g 85 frrvty                                                                   \
  && adduser --system --ingroup frr --home /var/run/frr/                                        \
    --gecos "FRR suite" --shell /sbin/nologin frr                                               \
  && usermod -a -G frrvty frr                                                                   \
  && install -m 775 -o frr -g frr -d /var/log/frr                                               \
  && install -m 775 -o frr -g frrvty -d /etc/frr                                                \
  && install -m 640 -o frr -g frrvty tools/etc/frr/vtysh.conf /etc/frr/vtysh.conf               \
  && install -m 640 -o frr -g frr tools/etc/frr/frr.conf /etc/frr/frr.conf                      \
  && install -m 640 -o frr -g frr tools/etc/frr/daemons.conf /etc/frr/daemons.conf              \
  && install -m 640 -o frr -g frr tools/etc/frr/daemons /etc/frr/daemons                        \
  && install -m 644 tools/frr.service /etc/systemd/system/frr.service                           \
  && sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons                                           \
  && sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons                                         \
  && sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
WORKDIR /hicn
WORKDIR /tmp
COPY init.sh .
WORKDIR /
CMD ["/tmp/init.sh"]
