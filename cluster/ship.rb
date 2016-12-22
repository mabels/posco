
=begin
{
  name      = "string"
  ifname    = "string"
  ipv4_addr = "v.x.y.z/p4|DHCP"
  ipv4_gw   = "v.x.y.zg|NULL"
  ipv6_addr = "v6::z6/p6"
  ipv6_gw   = "v6::z6g"
  ipv4_transit = "vt.xt.yt.zt/p4"
}
=end
def make_ship(region, parameter)
    #binding.pry if 'coreos' == parameter['dialect']
    return region.hosts.add(parameter['name'], "flavour" => "nixian",
                            "dialect" => parameter['dialect']||"ubuntu",
                            "update_channel" => "beta",
                            "image_version" => "current",
                            "packager" => true,
                           "services" => (parameter['services']||[]) + [
        Construqt::Flavour::Nixian::Services::Vagrant::Service.new.box("ubuntu/xenial64")
               .add_cfg('config.vm.network "public_network", bridge: "bridge0"')
     ]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        addr = DynamicAddress.creator(host, region.network.addresses, parameter)
        my.interfaces << region.interfaces.add_device(host, parameter['ifname'], "mtu" => 1500,
              "address" => addr,
              'proxy_neigh' => Construqt::Tags.resolver_adr_net(parameter['proxy_neigh_host'], parameter['proxy_neigh_net'], Construqt::Addresses::IPV6),
              "firewalls" => ["host-outbound", "icmp-ping", "ssh-srv", "border-masq"]+
                            (parameter['firewalls']||[]) +
                            ["block"])
        #binding.pry
      end
      region.interfaces.add_bridge(host, "br169", "mtu" => 1500,
                   "interfaces" => [],
                   "address" => region.network.addresses
                        .add_ip(parameter['ipv4_intern'])
                        .add_ip(parameter['ipv6_intern']))
    end
end

