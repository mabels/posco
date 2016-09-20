module SniProxy
  class Service
    include Construqt::Util::Chainable
    attr_reader :name
    attr_accessor :services
    chainable_attr_value :server_iface, nil
    def initialize(name)
      @name = name
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
          puts "hello world #{@name}"
          #                host.result.add(self, <<MAINCF, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::POSTFIX), "etc", "postfix", "main.cf")
          ## #{@service.get_server_iface.host.name} #{@service.get_server_iface.address.first_ipv4}
          #inet_protocols = all
          #myhostname = #{iface.host.name}
          #mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
          #MAINCF
        end
      end
    end
  end
end
Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(SniProxy::Service, SniProxy::Renderer::Nixian::Ubuntu)
