module Etcd
  class Service
    include Construqt::Util::Chainable
    attr_reader :name
    attr_accessor :services
    chainable_attr_value :server_iface, nil
    def initialize(name)
      @name = name
    end
    def self.add_component(cps)
      cps.register(Etcd::Service).add('etcd')
    end
  end


  module Renderer
    module Nixian
      class Ubuntu
        def initialize(service)
          @service = service
        end

        def interfaces(host, ifname, iface, writer, family = nil)
          return unless iface.address
          puts "#{@service.name} #{host.name} #{ifname} #{Construqt::Tags.find("ETCD_S").map{|i| i.container.name }}"
          domainname = "#{host.name}.#{host.region.network.domain}"
          cert_pkt = host.region.network.cert_store.find_package(domainname)
          host.result.add(self, cert_pkt.cert.content, Construqt::Resources::Rights.root_0600(Etcd::Service), "etc", "letsencrypt", "live", domainname, "cert.pem")
          host.result.add(self, cert_pkt.cacerts.map{|i|i.content}.join("\n"), Construqt::Resources::Rights.root_0600(Etcd::Service), "etc", "letsencrypt", "live", domainname, "fullchain.pem")
          host.result.add(self, cert_pkt.key.content, Construqt::Resources::Rights.root_0600(Etcd::Service), "etc", "letsencrypt", "live", domainname, "privkey.pem")
          ## #{@service.get_server_iface.host.name} #{@service.get_server_iface.address.first_ipv4}
          #inet_protocols = all
          Construqt::Tags.find("ETCD_S").each do |i|
            next if i.container.host.name == host.name
            domainname = "#{i.container.host.name}.#{host.region.network.domain}"
            cert_pkt = host.region.network.cert_store.find_package(domainname)
            host.result.add(self, cert_pkt.cert.content, Construqt::Resources::Rights.root_0600(Etcd::Service), "etc", "letsencrypt", "live", domainname, "cert.pem")
            host.result.add(self, cert_pkt.cacerts.map{|i|i.content}.join("\n"), Construqt::Resources::Rights.root_0600(Etcd::Service), "etc", "letsencrypt", "live", domainname, "fullchain.pem")
          end
          #myhostname = #{iface.host.name}
          #mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
          #MAINCF
        end
      end
    end
  end
end
Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(Etcd::Service, Etcd::Renderer::Nixian::Ubuntu)
