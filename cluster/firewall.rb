

def firewall(region)
  Construqt::Firewalls.add("fix-mss") do |fw|
    fw.forward do |fwd|
      fwd.add.from_net("").mss(1280).action(Construqt::Firewalls::Actions::TCPMSS)
    end
  end
  Construqt::Firewalls.add("border-forward") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_is_inside
    end
  end
  Construqt::Firewalls.add("border-masq") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).to_source.from_is_inside
    end
  end
  Construqt::Firewalls.add("net-nat") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("#INTERNAL-NET").from_filter_local.to_source.from_is_inside
    end
  end

  Construqt::Firewalls.add("net-forward") do |fw|
    fw.forward do |fordward|
      fordward.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#INTERNAL-NET").connection.from_filter_local.from_is_inside
    end

    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end
  end


  Construqt::Firewalls.add("icmp-ping") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET")
        .to_my_net.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    end

    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET")
        .to_net("#INTERNAL-NET").to_filter_local.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    end
  end

  Construqt::Firewalls.add("ssh-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(22).from_is_outside
    end
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(22).from_is_outside
    end
  end

  Construqt::Firewalls.add("https-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(443).from_is_outside
    end
  end

  Construqt::Firewalls.add("dns-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(53).from_is_outside
    end
  end

  Construqt::Firewalls.add("etcd-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(2381).dport(2382).from_is_outside
    end
  end

  Construqt::Firewalls.add("host-outbound") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end

    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNAL-NET").to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("block") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local.from_is_outside
      host.add.action(Construqt::Firewalls::Actions::DROP).log("HOST")
    end

    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::DROP).log("FORWARD")
    end
  end

end

def tunator_firewall(name)
  Construqt::Firewalls.add("#{name}-tunator") do |fw|
    fw.host do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.ipv6
        .from_host("##{name}-posco")
        .to_host("##{name}-tunator")
        .tcp.dport(4711).from_is_outside
    end
  end
end

def mother_firewall(name)
  Construqt::Firewalls.add("#{name}-ipv4-map-dns") do |fw|
    fw.nat do |nat|
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).
        from_net("#INTERNET")
        .to_me
        .udp.dport(53).to_dest("##{name}-DNS_MAPPED").from_is_outside
    end
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection
        .from_net("#INTERNET")
        .to_host("##{name}-DNS_MAPPED")
        .udp.dport(53).from_is_outside
    end
  end
  Construqt::Firewalls.add("#{name}-ipv4-map-sni") do |fw|
    fw.nat do |nat|
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).
        from_net("#INTERNET")
        .to_me.ipv4
        .tcp.dport(443).to_dest("##{name}-SNI_MAPPED").from_is_outside
    end
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection
        .from_net("#INTERNET")
        .to_host("##{name}-SNI_MAPPED")
        .tcp.dport(443).from_is_outside
    end
  end
  Construqt::Firewalls.add("#{name}-posco") do |fw|
    fw.host do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection
        .from_net("#INTERNET")
        .to_host("##{name}-POSCO_MAPPED")
        .tcp.dport(8443).from_is_outside
    end
  end
  Construqt::Firewalls.add("#{name}-ipv4-map-certor") do |fw|
    fw.nat do |nat|
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).ipv4
        .from_net("#INTERNET").to_me
        .tcp.dport(443).to_dest("##{name}-CERTOR_MAPPED").from_is_outside
    end
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection
        .from_net("#INTERNET")
        .to_host("##{name}-CERTOR_MAPPED")
        .tcp.dport(443).from_is_outside
    end
  end
  Construqt::Firewalls.add("#{name}-map-https-8443") do |fw|
    fw.nat do |nat|
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).ipv6.ipv4
        .from_net("#INTERNET").to_me
        .tcp.dport(443).to_dest("##{name}-CERTOR_MAPPED", 8443).from_is_outside
    end
    fw.host do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection
        .from_net("#INTERNET")
        .to_host("##{name}-CERTOR_MAPPED")
        .tcp.dport(8443).from_is_outside
    end
  end

  Construqt::Firewalls.add("#{name}-ipv6-etcd") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.ipv6
        .from_net("#INTERNET")
        .to_host("##{name}_ETCD_S")
        .tcp.dport(2382).dport(2381).from_is_outside
    end
  end
end
