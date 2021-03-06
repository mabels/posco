
module DynamicAddress
  def self.creator(host, addr, parameter)
    if parameter['dynamic']
      parameter['dynamic'].creator(host, addr, parameter)
    else
      if parameter['ipv4_addr'] == "DHCP"
        addr = addr.add_ip(Construqt::Addresses::DHCPV4)
      else
        addr = addr.add_ip(parameter['ipv4_addr'])
      end
      if parameter['ipv4_gw']
        addr = addr.add_route("0.0.0.0/0#INTERNET", parameter['ipv4_gw'])
      end
      addr = addr.add_ip(parameter['ipv6_addr'])
      if parameter['ipv6_gw'] && !parameter['ipv6_gw'].empty?
        addr = addr.add_route("2000::/3#INTERNET", parameter['ipv6_gw'])
        addr = addr.add_route("fd00::/8#INTERNET", parameter['ipv6_gw'])
      else
        addr = addr.add_route(Construqt::Addresses::RAV6)
      end
    end
  end
end
