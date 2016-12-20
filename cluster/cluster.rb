
begin
  require 'pry'
rescue LoadError
end

CONSTRUQT_PATH = ENV['CONSTRUQT_PATH'] || '../../../'
[
  "#{CONSTRUQT_PATH}/ipaddress/ruby/lib",
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/plantuml/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/gojs/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/ubuntu/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/coreos/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/services/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/entities/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/systemd/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/flat/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/debian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/file/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/mikrotik/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/dialects/hp/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/unknown/lib"
].each { |path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'
require 'construqt/flavour/nixian'
require 'construqt/flavour/nixian/dialect/ubuntu'
require 'construqt/flavour/nixian/dialect/coreos'

require_relative 'ship.rb'
require_relative 'service.rb'
require_relative 'firewall.rb'

[
 'digital_ocean.rb',
 'vultr.rb',
 'dns_service.rb',
 'etcd_service.rb',
 'certor_service.rb',
 'posco_service.rb',
 'sni_proxy_service.rb',
 'tunator_service.rb'
].each do |f|
  require_relative f
end


def setup_region(name, network)
  region = Construqt::Regions.add(name, network)
  nixian = Construqt::Flavour::Nixian::Factory.new
  nixian.services_factory.add(DigitalOcean::Factory.new)
  nixian.services_factory.add(Vultr::Factory.new)
  nixian.services_factory.add(Dns::Factory.new)
  nixian.services_factory.add(Etcd::Factory.new)
  nixian.services_factory.add(Certor::Factory.new)
  nixian.services_factory.add(SniProxy::Factory.new)
  nixian.services_factory.add(Posco::Factory.new)
  nixian.services_factory.add(Tunator::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Ubuntu::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::CoreOs::Factory.new)
  region.flavour_factory.add(nixian)
  if ARGV.include?('plantuml')
    require 'construqt/flavour/plantuml.rb'
    region.add_aspect(Construqt::Flavour::Plantuml.new)
  end

  region.network.ntp.add_server(region.network.addresses.add_ip('5.9.110.236').add_ip('178.23.124.2')).timezone('MET')
  region.users.add('menabe', 'group' => 'admin', 'full_name' => 'Meno Abels', 'public_key' => <<KEY, 'email' => 'meno.abels@construqt.net')
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIQpC2scaVXEaNuwtq4n6Vtht2WHYxtDFKe44JNFEsZGyQjyL9c2qkmQQGCF+2g3HrIPDTCCCWQ3GUiXGAlQ0/rf6sLqcm4YMXt+hgHU5VeciUIDEySCKdCPC419wFPBw6oKdcN1pLoIdWoF4LRDcjcrKKAlkdNJ/oLnl716piLdchABO9NXGxBpkLsJGK8qw390O1ZqZMe9wEAL9l/A1/49v8LfzELp0/fhSmiXphTVI/zNVIp/QIytXzRg74xcYpBjHk1TQZHuz/HYYsWwccnu7vYaTDX0CCoAyEt599f9u+JQ4oW0qyLO0ie7YcmR6nGEW4DMsPcfdqqo2VyYy4ix3U5RI2JcObfP0snYwPtAdVeeeReXi3c/E7bGLeCcwdFeFBfHSA9PDGxWVlxh/oCJaE7kP7eBhXNjN05FodVdNczKI5T9etfQ9VHILFrvpEREg1+OTiI58RmwjxS5ThloqXvr/nZzhIwTsED0KNW8wE4pjyotDJ8jaW2d7oVIMdWqE2M9Z1sLqDDdhHdVMFxk6Hl2XfqeqO2Jnst7qzbHAN/S3hvSwysixWJEcLDVG+cg1KRwz4qafCU5oHSp8aNNOk4RZozboFjac17nOmfPfnjC/LLayjSkEBZ+eFi+njZRLDN92k3PvHYFEB3USbHYzICsuDcf+L4cslX03g7w== openpgp:0x5F1BE34D
KEY
  region.users.add('martin', 'group' => 'admin', 'full_name' => 'Martin Meier', 'public_key' => <<KEY, 'email' => 'martin@protonet.info')
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDtG5uO8WF72Wh6uLAsFOgae7lgFn4R/z7nODuw+1QvAKdTZ44YTKkSPlwa2nvzxrB8Mefv08lbDUvad2o93GvXzM7N1XHxumVshFrNsse0Qe+fPrUs/17Yeqt6oZVDvQlo6iEnph6fg3L10Qi3xmKvHNqPqMV7vKrMnYd0Q/NzqVkSdX5SOBrVKui18JRbCrxz5Ld9Jk2SsaR/kEBOdM/QlT6PHCxlVGd0JSdMb6DtvehPH+DdUHI4jdydH6Pq/gHU9SeMdy0J/ZJJuCLit392AnZm50lB366LSEcm423Kb3W5JdClyg8Q/+Kw2HXoQHwS4qX1SxW8UtOmwo2iVwA9E4a2L7ymAu7c7yHKozZg+mKnkO+XUgcLod9GKylVFtsOmu9kHBDIi3M73byMEiCs+2CXRkWUH+yrnKCAT3HzO870mVHel7JRqyxR1WfeMXq8rRXq2NcgZ7/igi9Rt/OJEcxtwIP+QE8TQSNr3mfikXaKWJMneZ4FykZsiRPHKtoGwfrhv+ooTb6pQbr4zPGTDfGxIo37NnIDiI0wShjCsXPuLd49F6xEAT9LdhNAjpYS1PWEvSfy6w7JldSJ7xxE2GSGN/VfXNh0h6Fbut0aVcpllKGJA1IB007rdEHW3hH7G3nW7HZfWCl0FNsGhqi+2P2GxxOYxSy9Zl3wFLBytQ== martin@cerberusssh
KEY

  region
end

def cluster_json
   return <<JSON
{
    "etcbinds":[
    {
    "name":"1",
    "dialect": "coreos",
    "ifname": "eth0",
    "ipv4_extern":"192.168.202.220/24",
    "ipv4_addr":"192.168.202.220/24",
    "ipv4_gw":"192.168.202.1",
    "ipv6_addr":"fd00:202::192:168:202:220/64",
    "ipv6_gw":"fd00:202::192:168:202:1",
    "ipv4_intern":"169.254.200.1/24",
    "ipv6_intern":"fd00:202::192:168:200:1/112"
  },
  {
    "name":"2",
    "ipv4_extern":"192.168.202.230/24",
    "ipv4_addr":"192.168.202.230/24",
    "ipv4_gw":"192.168.202.1",
    "ipv6_addr":"fd00:202::192:168:202:230/64",
    "ipv6_gw":"fd00:202::192:168:202:1",
    "ipv4_intern":"169.254.201.1/24",
    "ipv6_intern":"fd00:202::192:168:201:1/112"
  },
  {
    "name":"3",
    "ipv4_extern":"192.168.202.240/24",
    "ipv4_addr":"192.168.202.240/24",
    "ipv4_gw":"192.168.202.1",
    "ipv6_addr":"fd00:202::192:168:202:240/64",
    "ipv6_gw":"fd00::192:168:202:1",
    "ipv4_intern":"169.254.202.1/24",
    "ipv6_intern":"fd00:202::192:168:202:1/112"
  }],
  "vips":[
  {
    "name":"1",
    "dialect": "coreos",
    "ifname": "eth1",
    "ipv4_extern":"10.24.1.210/24",
    "ipv4_addr":"10.24.1.210/24",
    "ipv4_gw":"10.24.1.1",
    "ipv6_addr":"fd00::10:24:1:210/64",
    "ipv6_gw":"fd00::10:24:1:1",
    "ipv4_intern":"169.254.210.1/24",
    "ipv6_intern":"fd00::169:254:210:1/112"
  },
  {
    "name":"2",
    "ipv4_extern":"10.24.1.211/24",
    "ipv4_addr":"10.24.1.211/24",
    "ipv4_gw":"10.24.1.1",
    "ipv6_addr":"fd00::10:24:1:211/64",
    "ipv6_gw":"fd00::10:24:1:1",
    "ipv4_intern":"169.254.211.1/24",
    "ipv6_intern":"fd00::169:254:211:1/112"
  },
  {
    "name":"3",
    "ipv4_extern":"10.24.1.212/24",
    "ipv4_addr":"10.24.1.212/24",
    "ipv4_gw":"10.24.1.1",
    "ipv6_addr":"fd00::10:24:1:212/64",
    "ipv6_gw":"fd00::10:24:1:1",
    "ipv4_intern":"169.254.212.1/24",
    "ipv6_intern":"fd00::169:254:212:1/112"
  }],
  "certs":{
    "path":"../../certs/"
  },
  "dns" : {
    "path":"../../dns/"
  },
  "cerberus": "cetcd",
  "domain":"adviser.com",
  "email":"meno.abels@adviser.com"
}
JSON
end

def get_config
  fname = "#{ENV['USER']}.cfg.json"
  obj = JSON.parse(if File.exists?(fname)
    IO.read(fname)
  else
    cluster_json
  end)
  ["etcbinds","vips"].each do |i|
    obj[i].each do |j|
      hostname = "#{i[0..-2]}-#{j['name']}"
      droplet_json = File.join("cfgs",hostname,"droplet.json")
      if File.exists?(droplet_json)
        droplet = JSON.parse(IO.read(droplet_json))
        droplet['networks']['v4'].each do |addr|
          host_ip = IPAddress.parse("#{addr['ip_address']}/#{addr['netmask']}")
          host_gateway = IPAddress.parse(addr['gateway'])
          j['ipv4_extern'] = host_ip.to_string
          j['ipv4_addr'] = host_ip.to_string
          j['ipv4_gateway'] = host_gateway.to_s
        end
        droplet['networks']['v6'].each do |addr|
          host_ip = IPAddress.parse("#{addr['ip_address']}/#{addr['netmask']}")
          host_gateway = IPAddress.parse(addr['gateway'])
          j['ipv6_addr'] = host_ip.to_string
          j['ipv6_gw'] = host_gateway.to_s
          j['ipv6_intern'] = "#{host_ip.inc.to_s}/124"
        end
      end
    end
  end
  obj
end


nss = NameServerSets.load(get_config['dns'])

network = Construqt::Networks.add('protonet')
network.set_domain(get_config['domain'])
network.set_contact(get_config['email'])
network.set_dns_resolver(network.addresses.set_name('NAMESERVER')
  .add_ip('8.8.8.8')
  .add_ip('8.8.4.4')
  .add_ip('2001:4860:4860::8888')
  .add_ip('2001:4860:4860::8844'),[get_config['domain']])
region = setup_region('protonet', network)
#region.services.add(Dns::Service.new('DNS', nss))


firewall(region)

version = SecureRandom.base64[0..20]
base = 200

def services_parse(srvs)
  (srvs||[]).map do |key, srv|
    if key == "DigitalOcean::Service"
      DigitalOcean::Service.from(srv)
    end
    if key = "Vultr::Service"
      Vultr::Service.from(srv)
    end
  end
end

def pullUp(p)
  OpenStruct.new(p.merge(
    'services' => services_parse(p['services']),
    'ipv4_addr' => IPAddress.parse(p['ipv4_addr']),
    'ipv4_gw' => IPAddress.parse(p['ipv4_gw']),
    'ipv6_addr' => IPAddress.parse(p['ipv6_addr']),
    'ipv6_gw' => IPAddress.parse(p['ipv6_gw']),
    'ipv4_intern' => IPAddress.parse(p['ipv4_intern']),
    'ipv6_intern' => IPAddress.parse(p['ipv6_intern'])
  ))
end

def get_config_and_pullUp(key)
  get_config[key].map{|x| pullUp(x) }
end

def load_certs(network)
  Dir.glob(File.join(get_config["certs"]["path"]||'/etc/letsencrypt/live',"*")).each do|dname|
    next unless File.directory?(dname)
      Construqt.logger.info "Reading Certs for #{File.basename(dname)}"
            network.cert_store.create_package(File.basename(dname),
              network.cert_store.add_private(File.basename(dname),IO.read(File.join(dname,'privkey.pem'))),
              network.cert_store.add_cert(File.basename(dname),IO.read(File.join(dname,'cert.pem'))),
              [network.cert_store.add_cacert(File.basename(dname),IO.read(File.join(dname,'chain.pem')))]
             )
  end
end

load_certs(network)

etcbinds = get_config_and_pullUp("etcbinds").map do |j|
  #binding.pry
  mother_firewall(j.name)
  ship = make_ship(region,
                   'services' => j.services,
                   'name' => "etcbind-#{j.name}",
                   'firewalls' => ["#{j.name}-ipv4-map-dns", "#{j.name}-ipv4-map-certor","#{j.name}-ipv6-etcd"],
                   'ifname'    => j.ifname||'enp0s8',
                   'dialect'   => j.dialect,
                   'proxy_neigh_host' => "##{j.name}_GW_S##{j.name}_DNS_S##{j.name}_ETCD_S##{j.name}_CERTOR_S",
                   'ipv4_addr' => "#{j.ipv4_addr.to_string}##{j.name}_DNS_S##{j.name}_CERTOR_S",
                   'ipv4_gw'   => j.ipv4_gw.to_s,
                   'ipv6_addr' => j.ipv6_addr.to_string,
                   'ipv6_gw'   => j.ipv6_gw.to_s,
                   'ipv4_intern' => j.ipv4_intern.to_string,
                   'ipv6_intern' => "#{j.ipv6_intern.to_string}##{j.name}_GW_S#GW_S")
  ipv4 = j.ipv4_intern.inc
  ipv6 = j.ipv6_intern.inc
  make_service(region, 'service' => Dns::Service.new(get_config['dns']),
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "dns-#{j.name}",
               'image'     => 'ubuntu:xenial',
               'packages'  => ['bind9'],
               'firewalls' => ['dns-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => nss.names,
               'ipv4_addr' => "#{ipv4.to_string.to_s}##{j.name}-DNS_MAPPED",
               'ipv4_gw'   => j.ipv4_intern.to_s,
               'ipv6_addr' => "#{ipv6.to_string}##{j.name}-DNS_MAPPED##{j.name}_DNS_S#DNS_S",
               'ipv6_gw'   => j.ipv6_intern.to_s,
               'version'   => version)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  make_service(region, 'service' => Etcd::Service.new,
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "etcd-#{j.name}",
               'image'     => 'quay.io/coreos/etcd',
               'pkt_man'   => :apk,
               'firewalls' => ['etcd-srv'],
               'ifname'    => 'eth0',
               'maps'      => [["/var/lib/etcd/data/etcd-#{j.name}", "/var/lib/etcd/data"]],
               'rndc_key'  => 'total geheim',
               'domains'   => nss.names,
               'ipv6_addr' => "#{ipv6.to_string}##{j.name}-ETCD_MAPPED##{j.name}_ETCD_S#ETCD_S",
               'ipv6_gw'   => j.ipv6_intern.to_s,
               'version'   => version)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  make_service(region, 'service' => Certor::Service.new,
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "certor-#{j.name}",
               'image'     => 'fastandfearless/certor:ubuntu-16-04-b2f0b34',
               'firewalls' => ["#{j.name}-map-https-8443"],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => nss.names,
               'ipv4_addr' => "#{ipv4.to_string.to_s}##{j.name}-CERTOR_MAPPED#CERTOR_S",
               'ipv4_gw'   => "169.254.#{base}.1",
               'ipv6_addr' => "#{ipv6.to_string}##{j.name}-CERTOR_MAPPED##{j.name}_CERTOR_S#CERTOR_S",
               'ipv6_gw'   => j.ipv6_intern.to_s,
               'version'   => version)
  base += 1
  ship
end

vips = get_config_and_pullUp("vips").map do |j|
  ship = make_ship(region, 'name' => "vips-#{j.name}",
                   'ifname'    => j.ifname||'enp0s8',
                   'dialect'   => j.dialect,
                   'firewalls' => ["#{j.name}-ipv4-map-sni", "#{j.name}-posco"],
                   'proxy_neigh_host' => "##{j.name}_SNI_S##{j.name}_POSCO_S##{j.name}_TUNATOR_S",
                   'proxy_neigh_net' => "##{j.name}_TUNATOR_S_NET",
                   'ipv4_addr' => "#{j.ipv4_addr.to_string}#DNS_S#CERTOR_S",
                   'ipv4_gw'   => j.ipv4_gw.to_s,
                   'ipv6_addr' => j.ipv6_addr.to_string,
                   'ipv6_gw'   => j.ipv6_gw.to_s,
                   'ipv4_intern' => j.ipv4_intern.to_string,
                   'ipv6_intern' => j.ipv6_intern.to_string)
  ipv4 = j.ipv4_intern.inc
  ipv6 = j.ipv6_intern.inc
  make_service(region, 'service' => SniProxy::Service.new,
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "sniproxy-#{j.name}",
               'image'     => 'fastandfearless/sniproxy:ubuntu-16-04-b2f0b34',
               'firewalls' => ['https-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => nss.names,
               'ipv6_addr' => "#{ipv6.to_string}#SNIPROXY_S##{j.name}-SNI_MAPPED##{j.name}_SNI_S",
               'ipv6_gw'   => j.ipv6_intern.to_string,
               'version'   => version)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  make_service(region, 'service' => Posco::Service.new,
               'mother'    => ship,
               'mother_if' => 'br169',
               'image'     => 'fastandfearless/node:ubuntu-16-04-b2f0b34',
               'name'      => "poscos-#{j.name}",
               'firewalls' => ['https-srv'],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => nss.names,
               'ipv6_addr' => "#{ipv6.to_string}#POSCO_S##{j.name}-posco##{j.name}-POSCO_MAPPED##{j.name}_POSCO_S",
               'ipv6_gw'   => j.ipv6_intern.to_string,
               'version'   => version)
  ipv4 = ipv4.inc
  ipv6 = ipv6.inc
  tunator_firewall(j.name)
  tunator_block_ofs = j.ipv6_intern.size().shr(1)
  tunator_block = j.ipv6_intern.network.add_num(tunator_block_ofs).change_prefix(119)
  region.network.addresses.add_ip("#{tunator_block.to_string}##{j.name}_TUNATOR_S_NET")
  make_service(region, 'service' => Tunator::Service.new,
               'mother'    => ship,
               'mother_if' => 'br169',
               'name'      => "tunators-#{j.name}",
               'image'     => 'fastandfearless/tunator:ubuntu-16-04-c79bd0b',
               'firewalls' => ["#{j.name}-tunator"],
               'ifname'    => 'eth0',
               'rndc_key'  => 'total geheim',
               'domains'   => nss.names,
               'ipv6_proxy_neigh' => "##{j.name}_TUNATOR_S_NET",
               'ipv4_addr' => "#{ipv4.to_string}",
               'ipv4_gw'   => j.ipv4_intern.to_string,
               'ipv6_addr' => "#{ipv6.to_string}#TUNATOR_S##{j.name}-tunator##{j.name}_TUNATOR_S",
               'ipv6_gw'   => j.ipv6_intern.to_string)

end
region.hosts.add(get_config()["cerberus"], "flavour" => "nixian", "dialect" => "ubuntu",
                "services" => [Construqt::Flavour::Nixian::Services::Vagrant::Service.new.box("ubuntu/xenial64")
                    .add_cfg('config.vm.network "public_network", bridge: "bridge0"')]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|

        my.interfaces << iface = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
            "address" => region.network.addresses.add_ip(Construqt::Addresses::DHCPV4),"firewalls" => ["border-masq"])
      end
      region.interfaces.add_bridge(host, 'bridge0',"mtu" => 1500,
                                                   "interfaces" => [],
                                                   "address" => region.network.addresses.add_ip("10.24.1.1/24",
                                                   "dhcp" => Construqt::Dhcp.new.start("10.24.1.100")
                                                     .end("10.24.1.110").domain("cerberus"))
                                                     .add_ip("fd00::10:24:1:1/64#ETCD_CLIENTS"))
    end

Construqt.produce(region)
