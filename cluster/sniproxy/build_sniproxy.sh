
echo $DOCKER_HOST
auth=$(ruby -e 'require "json"; puts JSON.parse(IO.read("#{ENV["HOME"]}/.docker/config.json"))["auths"]["https://index.docker.io/v1/"]["auth"]')
docker build -t build-sniproxy .
docker run -ti --rm --privileged multiarch/qemu-user-static:register --reset
#--privileged 
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /sniproxy-build:/sniproxy-build  --env "DOCKER_AUTH=$auth" -t build-sniproxy

#/bin/bash
