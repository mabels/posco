=begin
{
  mother    = host_instance
  mother_if = "string"
  name      = "string"
  ipv4_addr = "v.x.y.z/p4"
  ipv4_gw   = "v.x.y.zg"
  ipv6_addr = "v6::z6/p6"
  ipv6_gw   = "v6::z6g"
}
=end
def make_service(region, parameter)

    updowner = Construqt::Flavour::Nixian::Services::UpDowner::Service.new
                                    .taste(Construqt::Flavour::Nixian::Tastes::File::Factory.new)

    docker = Construqt::Flavour::Nixian::Services::Docker::Service.new
                                    .image(parameter['image'])
                                    .pkt_man(parameter['pkt_man']||:apt)
                                    .privileged
    (parameter['maps']||[]).each do |map|
      docker.map(map.first, map.last)
    end
    (parameter['packages']||[]).each do |pkg|
      docker.package(pkg)
    end

    return region.hosts.add(parameter['name'], "flavour" => "nixian", "dialect" => "ubuntu",
                            "mother" => parameter['mother'],
                            "services" => [docker, updowner]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        addr = region.network.addresses
        addr = addr.add_ip(parameter['ipv4_addr']) if parameter['ipv4_addr']
        addr = addr.add_route("0.0.0.0/0", parameter['ipv4_gw']) if parameter['ipv4_gw']
        addr = addr.add_ip(parameter['ipv6_addr'])
        addr = addr.add_route("2000::/3", parameter['ipv6_gw'])
        addr = addr.add_route("fd00::/8", parameter['ipv6_gw'])


        p = {
            "mtu" => 1500,
            "plug_in" => Construqt::Cables::Plugin.new.iface(parameter['mother'].interfaces.find_by_name(parameter['mother_if'])),
            "firewalls" => ["host-outbound", "icmp-ping", "ssh-srv"]+
                            (parameter['firewalls']||[]) +
                            ["block"],
            "address" => addr
        }
        if parameter['ipv6_proxy_neigh']
          #binding.pry
          p['proxy_neigh'] = Construqt::Tags.resolver_net(parameter['ipv6_proxy_neigh'], Construqt::Addresses::IPV6)
        end

        my.interfaces << iface = region.interfaces.add_device(host, "eth0", p)
        #region.cables.add(iface, region.interfaces.find(parameter['mother'], parameter['mother_if']))
        iface.services.add(parameter['service'].domains(parameter['domains']).server_iface(iface))
      end
    end
end
