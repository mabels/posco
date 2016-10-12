#!/bin/bash
#/etc/init.d/docker start
(cd /sniproxy-build && git clone --bare https://github.com/dlundquist/sniproxy.git)
for arch in multiarch/ubuntu-core:armhf-xenial multiarch/ubuntu-core:arm64-xenial ubuntu:16.04 
do
  (
  farch=$(echo $arch | sed 's/[^a-zA-Z0-9]/-/g')
  mkdir build-$farch
  cd build-$farch
  cat > docker_compile.sh <<EOF
apt-get update
apt-get upgrade -y
apt-get install -y -q git autotools-dev cdbs debhelper dh-autoreconf dpkg-dev gettext libev-dev libpcre3-dev libudns-dev pkg-config fakeroot devscripts
mkdir -p /sniproxy-build/$farch
git clone /sniproxy-build/sniproxy.git
(cd sniproxy && \
   git rev-parse --verify --short HEAD > /sniproxy-build/$farch/VERSION && \
  ./autogen.sh && dpkg-buildpackage)
cp sniproxy*.deb /sniproxy-build/$farch
EOF
#if [ "$arch" = "ubuntu:16:04" ]
#then
  echo "Setup $arch"
  EUM=""
  CMD="CMD [\"/bin/bash\", \"/docker_compile.sh\"]"
  COPY=""
  APT="\"apt\""
  SH="\"/bin/sh\""
  DIGN=""
#fi
if [ $arch = "multiarch/ubuntu-core:armhf-xenial" ]
then
  EMU="/usr/bin/qemu-arm-static"
  CMD="CMD [\"$EMU\", \"/bin/bash\", \"/docker_compile.sh\"]"
  APT="\"$EMU\", \"/usr/bin/apt\""
  SH="\"$EMU\", \"/bin/sh\""
  COPY="COPY $(basename $EMU) $EMU"
  COPY=""
  DIGN="!$(basename $EMU)"
  mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
  echo -1 > /proc/sys/fs/binfmt_misc/arm
  echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:' > /proc/sys/fs/binfmt_misc/register
#  cp $EMU .
fi
if [ $arch = "multiarch/ubuntu-core:arm64-xenial" ]
then
  EMU="/usr/bin/qemu-aarch64-static"
  CMD="CMD [\"$EMU\", \"/bin/bash\", \"/docker_compile.sh\"]"
  COPY="COPY $(basename $EMU) $EMU"
  COPY=""
  APT="\"$EMU\", \"/usr/bin/apt\""
  SH="\"$EMU\", \"/bin/sh\""
  DIGN="!$(basename $EMU)"
  mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
  echo -1 > /proc/sys/fs/binfmt_misc/aarch64
  echo ':aarch64:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:' > /proc/sys/fs/binfmt_misc/register
#      k  :aarch64:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/qemu/qemu-aarch64-binfmt:P
#  cp $EMU .
fi

  cat > Dockerfile <<EOF
FROM $arch
$COPY
COPY docker_compile.sh /
$CMD
EOF
echo "builder for sniproxy-builder-$farch $arch-"
cat Dockerfile
#read a
  docker build -t sniproxy-builder-$farch .
echo "run for sniproxy-builder-$farch"
#read a
  docker run -v /sniproxy-build:/sniproxy-build -ti sniproxy-builder-$farch 
echo "done for sniproxy-builder-$farch"
#read a

cp /sniproxy-build/$farch/*.deb .
cp /sniproxy-build/$farch/VERSION .
pwd
ls -la
cat > Dockerfile <<RUNNER
FROM $arch
$COPY
COPY *.deb /
RUN [$APT, "update", "-y"]
RUN [$APT, "upgrade", "-y"]
RUN [$APT, "install", "-y", "-q", "libev4", "libudns0" ]
RUN [$SH, "-c", "dpkg -i /sniproxy_*.deb"]
COPY VERSION /

CMD ["/etc/init.d/sniproxy", "start"]
RUNNER

cat > .dockerignore <<RUNNER
*
!*.deb
!VERSION
$DIGN
RUNNER

mkdir -p $HOME/.docker
cat > $HOME/.docker/config.json <<RUNNER
{
	"auths": {
		"https://index.docker.io/v1/": {
			"auth": "$DOCKER_AUTH"
		}
	}
}
RUNNER
echo "done for sniproxy-$farch"
cat Dockerfile
#read a
docker build -t sniproxy-$farch .
echo "done for sniproxy-$farch"
#read a
TVERSION=$farch-$(cat /sniproxy-build/$farch/VERSION)
docker images
echo docker tag sniproxy-$farch fastandfearless/sniproxy:$TVERSION
docker tag sniproxy-$farch fastandfearless/sniproxy:$TVERSION
echo "done for sniproxy-$farch"
#read a
echo docker push fastandfearless/sniproxy:$TVERSION
docker push fastandfearless/sniproxy:$TVERSION
echo "done for sniproxy-$farch"
#read a
)
done
