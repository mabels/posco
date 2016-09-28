
begin
  require 'pry'
rescue LoadError
end

CONSTRUQT_PATH = ENV['CONSTRUQT_PATH'] || '../../'
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
].each { |path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'
require 'construqt/flavour/nixian'
require 'construqt/flavour/nixian/dialect/ubuntu'

require_relative 'ship.rb'
require_relative 'service.rb'
require_relative 'firewall.rb'

def setup_region(name, network)
  region = Construqt::Regions.add(name, network)
  nixian = Construqt::Flavour::Nixian::Factory.new
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Ubuntu::Factory.new)
  region.flavour_factory.add(nixian)
  if ARGV.include?('plantuml')
    require 'construqt/flavour/plantuml.rb'
    region.add_aspect(Construqt::Flavour::Plantuml.new)
  end

  region.network.ntp.add_server(region.network.addresses.add_ip('5.9.110.236').add_ip('178.23.124.2')).timezone('MET')
  region.users.add('menabe', 'group' => 'admin', 'full_name' => 'Meno Abels', 'public_key' => <<KEY, 'email' => 'meno.abels@construqt.net')
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIQpC2scaVXEaNuwtq4n6Vtht2WHYxtDFKe44JNFEsZGyQjyL9c2qkmQQGCF+2g3HrIPDTCCCWQ3GUiXGAlQ0/rf6sLqcm4YMXt+hgHU5VeciUIDEySCKdCPC419wFPBw6oKdcN1pLoIdWoF4LRDcjcrKKAlkdNJ/oLnl716piLdchABO9NXGxBpkLsJGK8qw390O1ZqZMe9wEAL9l/A1/49v8LfzELp0/fhSmiXphTVI/zNVIp/QIytXzRg74xcYpBjHk1TQZHuz/HYYsWwccnu7vYaTDX0CCoAyEt599f9u+JQ4oW0qyLO0ie7YcmR6nGEW4DMsPcfdqqo2VyYy4ix3U5RI2JcObfP0snYwPtAdVeeeReXi3c/E7bGLeCcwdFeFBfHSA9PDGxWVlxh/oCJaE7kP7eBhXNjN05FodVdNczKI5T9etfQ9VHILFrvpEREg1+OTiI58RmwjxS5ThloqXvr/nZzhIwTsED0KNW8wE4pjyotDJ8jaW2d7oVIMdWqE2M9Z1sLqDDdhHdVMFxk6Hl2XfqeqO2Jnst7qzbHAN/S3hvSwysixWJEcLDVG+cg1KRwz4qafCU5oHSp8aNNOk4RZozboFjac17nOmfPfnjC/LLayjSkEBZ+eFi+njZRLDN92k3PvHYFEB3USbHYzICsuDcf+L4cslX03g7w== openpgp:0x5F1BE34D
KEY

  ['dns_service.rb',
   'etcd_service.rb',
   'certor_service.rb',
   'posco_service.rb',
   'sni_proxy_service.rb',
   'tunator_service.rb'].each { |f| require_relative f }

  region.services.add(Dns::Service.new('DNS'))
  region.services.add(Etcd::Service.new('ETCD'))
  region.services.add(Certor::Service.new('CERTOR'))
  region.services.add(SniProxy::Service.new('SNIPROXY'))
  region.services.add(Posco::Service.new('POSCO'))
  region.services.add(Tunator::Service.new('TUNATOR'))

  region
end

network = Construqt::Networks.add('protonet')
network.set_domain('construqt.net')
network.set_contact('meno.abels.construqt.net')
network.set_dns_resolver(network.addresses.set_name('NAMESERVER')
  .add_ip('8.8.8.8')
  .add_ip('8.8.4.4')
  .add_ip('2001:4860:4860::8888')
  .add_ip('2001:4860:4860::8844'), [network.domain])
region = setup_region('protonet', network)

firewall(region)

base = 200

def pullUp(p)
  OpenStruct.new(p.merge(
    'ipv4_addr' => IPAddress.parse(p['ipv4_addr']),
    'ipv4_gw' => IPAddress.parse(p['ipv4_gw']),
    'ipv6_addr' => IPAddress.parse(p['ipv6_addr']),
    'ipv6_gw' => IPAddress.parse(p['ipv6_gw']),
    'ipv4_intern' => IPAddress.parse(p['ipv4_intern']),
    'ipv6_intern' => IPAddress.parse(p['ipv6_intern'])
  ))
end

etcbinds = [
  pullUp(
    'name' => 'eu-0',
    'ipv4_extern' => '10.24.1.200/24',
    'ipv4_addr' => '10.24.1.200/24',
    'ipv4_gw' => '10.24.1.1',
    'ipv6_addr' => 'fd00::10:24:1:200/64',
    'ipv6_gw' => 'fd00::10:24:1:1',
    'ipv4_intern' => '169.254.200.1/24',
    'ipv6_intern' => 'fd00::169:254:200:1/112'
  ),
  pullUp(
    'name' => 'eu-1',
    'ipv4_extern' => '10.24.1.201/24',
    'ipv4_addr' => '10.24.1.201/24',
    'ipv4_gw' => '10.24.1.1',
    'ipv6_addr' => 'fd00::10:24:1:201/64',
    'ipv6_gw' => 'fd00::10:24:1:1',
    'ipv4_intern' => '169.254.201.1/24',
    'ipv6_intern' => 'fd00::169:254:201:1/112'
  ),
  pullUp(
    'name' => 'us-0',
    'ipv4_extern' => '10.24.1.202/24',
    'ipv4_addr' => '10.24.1.202/24',
    'ipv4_gw' => '10.24.1.1',
    'ipv6_addr' => 'fd00::10:24:1:202/64',
    'ipv6_gw' => 'fd00::10:24:1:1',
    'ipv4_intern' => '169.254.202.1/24',
    'ipv6_intern' => 'fd00::169:254:202:1/112'
  )
].map do |j|
  mother_firewall(j.name)
  ship = make_ship(region, 'name' => "etcbind-#{j.name}",
                   'firewalls' => ["#{j.name}-ipv4-map-dns", "#{j.name}-ipv4-map-certor","#{j.name}-ipv6-etcd"],
                   'ifname'    => 'enp0s8',
                   'proxy_neigh_host' => "##{j.name}_GW_S##{j.name}_DNS_S##{j.name}_ETCD_S##{j.name}_CERTOR_S",
                   'ipv4_addr' => "#{j.ipv4_addr.to_string}##{j.name}_DNS_S##{j.name}_CERTOR_S",
                   'ipv4_gw'   => j.ipv4_gw.to_s,
                   'ipv6_addr' => j.ipv6_addr.to_string,
                   'ipv6_gw'   => j.ipv6_gw.to_s,
                   'ipv4_intern' => j.ipv4_intern.to_string,
                   'ipv6_intern' => "#{j.ipv6_intern.to_string}##{j.name}_GW_S#GW_S")
  ipv4 = j.ipv4_intern.inc
  ipv6 = j.ipv6_intern.inc
  make_service(region, 'service' => 'DNS',
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "dns-#{j.name}",
               'firewalls' => ['dns-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => [{ 'name' => 'construqt.net', 'basefile' => 'costruqt.net.zone' }],
               'ipv4_addr' => "#{ipv4.to_string.to_s}##{j.name}-DNS_MAPPED",
               'ipv4_gw'   => j.ipv4_intern.to_s,
               'ipv6_addr' => "#{ipv6.to_string}##{j.name}-DNS_MAPPED##{j.name}_DNS_S#DNS_S",
               'ipv6_gw'   => j.ipv6_intern.to_s)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  make_service(region, 'service' => 'ETCD',
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "etcd-#{j.name}",
               'firewalls' => ['etcd-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => [{ 'name' => 'construqt.n:et', 'basefile' => 'costruqt.net.zone' }],
               'ipv6_addr' => "#{ipv6.to_string}##{j.name}-ETCD_MAPPED##{j.name}_ETCD_S#ETCD_S",
               'ipv6_gw'   => j.ipv6_intern.to_s)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  make_service(region, 'service' => 'CERTOR',
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "certor-#{j.name}",
               'firewalls' => ["#{j.name}-ipv4-map-certor"],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => [{ 'name' => 'construqt.net', 'basefile' => 'costruqt.net.zone' }],
               'ipv4_addr' => "#{ipv4.to_string.to_s}##{j.name}-CERTOR_MAPPED#CERTOR_S",
               'ipv4_gw'   => "169.254.#{base}.1",
               'ipv6_addr' => "#{ipv6.to_string}##{j.name}-CERTOR_MAPPED##{j.name}_CERTOR_S#CERTOR_S",
               'ipv6_gw'   => j.ipv6_intern.to_s)
  base += 1
  ship
end

vips = [
  pullUp(
    'name' => 'eu-0',
    'ipv4_extern' => '10.24.1.210/24',
    'ipv4_addr' => '10.24.1.210/24',
    'ipv4_gw' => '10.24.1.1',
    'ipv6_addr' => 'fd00::10:24:1:210/64',
    'ipv6_gw' => 'fd00::10:24:1:1',
    'ipv4_intern' => '169.254.210.1/24',
    'ipv6_intern' => 'fd00::169:254:210:1/112'
  ),
  pullUp(
    'name' => 'eu-1',
    'ipv4_extern' => '10.24.1.211/24',
    'ipv4_addr' => '10.24.1.211/24',
    'ipv4_gw' => '10.24.1.1',
    'ipv6_addr' => 'fd00::10:24:1:211/64',
    'ipv6_gw' => 'fd00::10:24:1:1',
    'ipv4_intern' => '169.254.211.1/24',
    'ipv6_intern' => 'fd00::169:254:211:1/112'
  ),
  pullUp(
    'name' => 'us-0',
    'ipv4_extern' => '10.24.1.212/24',
    'ipv4_addr' => '10.24.1.212/24',
    'ipv4_gw' => '10.24.1.1',
    'ipv6_addr' => 'fd00::10:24:1:212/64',
    'ipv6_gw' => 'fd00::10:24:1:1',
    'ipv4_intern' => '169.254.212.1/24',
    'ipv6_intern' => 'fd00::169:254:212:1/112'
  )
].map do |j|
  ship = make_ship(region, 'name' => "vips-#{j.name}",
                   'ifname'    => 'enp0s8',
                   'firewalls' => ["#{j.name}-ipv4-map-sni", "#{j.name}-posco"],
                   'ipv4_addr' => "#{j.ipv4_addr.to_string}#DNS_S#CERTOR_S",
                   'ipv4_gw'   => j.ipv4_gw.to_s,
                   'ipv6_addr' => j.ipv6_addr.to_string,
                   'ipv6_gw'   => j.ipv6_gw.to_s,
                   'ipv4_intern' => j.ipv4_intern.to_string,
                   'ipv6_intern' => j.ipv6_intern.to_string)
  ipv4 = j.ipv4_intern.inc
  ipv6 = j.ipv6_intern.inc
  make_service(region, 'service' => 'SNIPROXY',
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "sniproxy-#{j.name}",
               'firewalls' => ['https-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => [{ 'name' => 'construqt.net', 'basefile' => 'costruqt.net.zone' }],
               'ipv6_addr' => "#{ipv6.to_string}#SNIPROXY_S##{j.name}-SNI_MAPPED",
               'ipv6_gw'   => j.ipv6_intern.to_string)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  make_service(region, 'service' => 'POSCO',
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "poscos-#{j.name}",
               'firewalls' => ['https-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => [{ 'name' => 'construqt.net', 'basefile' => 'costruqt.net.zone' }],
               'ipv6_addr' => "#{ipv6.to_string}#POSCO_S##{j.name}-posco##{j.name}-POSCO_MAPPED",
               'ipv6_gw'   => j.ipv6_intern.to_string)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  tunator_firewall(j.name)
  make_service(region, 'service' => 'TUNATOR',
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "tunators-#{j.name}",
               'firewalls' => ["#{j.name}-tunator"],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => [{ 'name' => 'construqt.net', 'basefile' => 'costruqt.net.zone' }],
               'ipv4_addr' => "#{ipv4.to_string}",
               'ipv4_gw'   => j.ipv4_intern.to_string,
               'ipv6_addr' => "#{ipv6.to_string}#TUNATOR_S##{j.name}-tunator",
               'ipv6_gw'   => j.ipv6_intern.to_string)
end

Construqt.produce(region)
