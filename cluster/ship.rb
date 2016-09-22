
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
    return region.hosts.add(parameter['name'], "flavour" => "nixian",
                            "dialect" => "ubuntu",
                            "packager" => true,
                           "vagrant_deploy" =>
              Construqt::Hosts::Vagrant.new.box("ubuntu/xenial64")
               .add_cfg('config.vm.network "public_network", bridge: "bridge0"')
     ) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        addr = region.network.addresses
        if parameter['ipv4_addr'] == "DHCP"
          addr = addr.add_ip(Construqt::Addresses::DHCPV4)
        else
          addr = addr.add_ip(parameter['ipv4_addr'])
        end
        if parameter['ipv4_gw']
          addr = addr.add_route("0.0.0.0/0", parameter['ipv4_gw'])
        end
        addr = addr.add_ip(parameter['ipv6_addr'])
        addr = addr.add_route("2000::/3", parameter['ipv6_gw'])
        my.interfaces << region.interfaces.add_device(host, parameter['ifname'], "mtu" => 1500,
                                                      "address" => addr)
      end
      region.interfaces.add_bridge(host, "br169", "mtu" => 1500,
                   "interfaces" => [],
                   "address" => region.network.addresses
                        .add_ip(parameter['ipv4_intern'])
                        .add_ip(parameter['ipv6_intern']))
    end
end

