
begin
  require 'pry'
rescue LoadError
end

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../'
[
  "#{CONSTRUQT_PATH}/ipaddress/ruby/lib",
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/plantuml/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/gojs/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/ubuntu/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/mikrotik/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/dialects/hp/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/unknown/lib"
].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'
require 'construqt/flavour/nixian'
require 'construqt/flavour/nixian/dialect/ubuntu'

require_relative 'ship.rb'
require_relative 'service.rb'


def setup_region(name, network)
  region = Construqt::Regions.add(name, network)
  nixian = Construqt::Flavour::Nixian::Factory.new
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Ubuntu::Factory.new)
  region.flavour_factory.add(nixian)
  if ARGV.include?("plantuml")
    require 'construqt/flavour/plantuml.rb'
    region.add_aspect(Construqt::Flavour::Plantuml.new)
  end

  region.network.ntp.add_server(region.network.addresses.add_ip("5.9.110.236").add_ip("178.23.124.2")).timezone("MET")
  region.users.add("menabe", "group" => "admin", "full_name" => "Meno Abels", "public_key" => <<KEY, "email" => "meno.abels@construqt.net")
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIQpC2scaVXEaNuwtq4n6Vtht2WHYxtDFKe44JNFEsZGyQjyL9c2qkmQQGCF+2g3HrIPDTCCCWQ3GUiXGAlQ0/rf6sLqcm4YMXt+hgHU5VeciUIDEySCKdCPC419wFPBw6oKdcN1pLoIdWoF4LRDcjcrKKAlkdNJ/oLnl716piLdchABO9NXGxBpkLsJGK8qw390O1ZqZMe9wEAL9l/A1/49v8LfzELp0/fhSmiXphTVI/zNVIp/QIytXzRg74xcYpBjHk1TQZHuz/HYYsWwccnu7vYaTDX0CCoAyEt599f9u+JQ4oW0qyLO0ie7YcmR6nGEW4DMsPcfdqqo2VyYy4ix3U5RI2JcObfP0snYwPtAdVeeeReXi3c/E7bGLeCcwdFeFBfHSA9PDGxWVlxh/oCJaE7kP7eBhXNjN05FodVdNczKI5T9etfQ9VHILFrvpEREg1+OTiI58RmwjxS5ThloqXvr/nZzhIwTsED0KNW8wE4pjyotDJ8jaW2d7oVIMdWqE2M9Z1sLqDDdhHdVMFxk6Hl2XfqeqO2Jnst7qzbHAN/S3hvSwysixWJEcLDVG+cg1KRwz4qafCU5oHSp8aNNOk4RZozboFjac17nOmfPfnjC/LLayjSkEBZ+eFi+njZRLDN92k3PvHYFEB3USbHYzICsuDcf+L4cslX03g7w== openpgp:0x5F1BE34D
KEY

  ["dns_service.rb",
   "etcd_service.rb",
   "certor_service.rb",
   "posco_service.rb",
   "sni_proxy_service.rb",
   "tunator_service.rb"].each {|f| require_relative f}

  region.services.add(Dns::Service.new("DNS"))
  region.services.add(Etcd::Service.new("ETCD"))
  region.services.add(Certor::Service.new("CERTOR"))
  region.services.add(SniProxy::Service.new("SNIPROXY"))
  region.services.add(Posco::Service.new("POSCO"))
  region.services.add(Tunator::Service.new("TUNATOR"))

  return region
end

network = Construqt::Networks.add('protonet')
network.set_domain("construqt.net")
network.set_contact("meno.abels.construqt.net")
network.set_dns_resolver(network.addresses.set_name("NAMESERVER").
                         add_ip("2001:4860:4860::8888").
                         add_ip("2001:4860:4860::8844"), [network.domain])
region = setup_region("winsen", network)

base = 200;


ship = make_ship(region, {
  'name'      => "posco-01",
  'ifname'    => "eth0",
  'ipv4_addr' => "10.24.1.#{base}/24",
  'ipv4_gw'   => "10.24.1.1",
  'ipv6_addr' => "fd00::10:24:1:#{base}/64",
  'ipv6_gw'   => "fd00::10:24:1:1",
  'ipv4_hostnet' => "10.25.2.1/24"
})

dnss = [0,1].map do |i|
  make_service(region, {
    'service'   => "DNS",
    'mother'    => ship,
    'mother_if' => "br0",
    'name'      => "dns-#{i}",
    'ifname'    => "eth0",
    'rndc_key'  => "total geheim",
    'domains'   => [{'name'=>'construqt.net','basefile'=>'costruqt.net.zone'}],
    'ipv4_addr' => "10.24.1.#{base+4+i}/24#DNS_S",
    'ipv4_gw'   => "10.24.1.1",
    'ipv6_addr' => "fd00::10:24:1:#{base+4+i}/64#DNS_S",
    'ipv6_gw'   => "fd00::10:24:1:1",
  })
end

etcds = [0,1,2].map do |i|
  make_service(region, {
    'service'   => "ETCD",
    'mother'    => ship,
    'mother_if' => "br0",
    'name'      => "etcd-#{i}",
    'ifname'    => "eth0",
    'rndc_key'  => "total geheim",
    'domains'   => [{'name'=>'construqt.net','basefile'=>'costruqt.net.zone'}],
    'ipv6_addr' => "fd00::10:24:1:#{base+8+i}/64#ETCD_S",
    'ipv6_gw'   => "fd00::10:24:1:1",
  })
end

certor = [0].map do |i|
  make_service(region, {
    'service'   => "CERTOR",
    'mother'    => ship,
    'mother_if' => "br0",
    'name'      => "certor-#{i}",
    'ifname'    => "eth0",
    'rndc_key'  => "total geheim",
    'domains'   => [{'name'=>'construqt.net','basefile'=>'costruqt.net.zone'}],
    'ipv6_addr' => "fd00::10:24:1:#{base+12+i}/64#ETCD_S",
    'ipv6_gw'   => "fd00::10:24:1:1",
  })
end

sniproxies = [0].map do |i|
  make_service(region, {
    'service'   => "SNIPROXY",
    'mother'    => ship,
    'mother_if' => "br0",
    'name'      => "sniproxy-#{i}",
    'ifname'    => "eth0",
    'rndc_key'  => "total geheim",
    'domains'   => [{'name'=>'construqt.net','basefile'=>'costruqt.net.zone'}],
    'ipv6_addr' => "fd00::10:24:1:#{base+16+i}/64#ETCD_S",
    'ipv6_gw'   => "fd00::10:24:1:1",
  })
end

poscos = [0].map do |i|
  make_service(region, {
    'service'   => "POSCO",
    'mother'    => ship,
    'mother_if' => "br0",
    'name'      => "poscos-#{i}",
    'ifname'    => "eth0",
    'rndc_key'  => "total geheim",
    'domains'   => [{'name'=>'construqt.net','basefile'=>'costruqt.net.zone'}],
    'ipv6_addr' => "fd00::10:24:1:#{base+24+i}/64#ETCD_S",
    'ipv6_gw'   => "fd00::10:24:1:1",
  })
end

tunators = [0].map do |i|
  make_service(region, {
    'service'   => "TUNATOR",
    'mother'    => ship,
    'mother_if' => "br0",
    'name'      => "tunators-#{i}",
    'ifname'    => "eth0",
    'rndc_key'  => "total geheim",
    'domains'   => [{'name'=>'construqt.net','basefile'=>'costruqt.net.zone'}],
    'ipv6_addr' => "fd00::10:24:1:#{base+28+i}/64#ETCD_S",
    'ipv6_gw'   => "fd00::10:24:1:1",
  })
end

Construqt.produce(region)
