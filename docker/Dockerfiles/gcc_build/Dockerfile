
# https://www.jwillikers.com/build-gcc-from-source-on-centos-7
FROM fedora:latest

RUN yum -y install dnf

RUN dnf -y install bzip2 wget gcc gcc-c++ gmp-devel mpfr-devel libmpc-devel make

WORKDIR /tmp

# find newest source here: https://ftp.gnu.org/gnu/gcc/
RUN curl -O https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.gz

RUN tar --extract --file=gcc-12.2.0.tar.gz

RUN mkdir gcc-build

WORKDIR /tmp/gcc-build

RUN ../gcc-12.2.0/configure --enable-languages=c,c++,fortran --disable-multilib --prefix=$HOME/.gcc/12.2.0

RUN make -j$(nproc)
