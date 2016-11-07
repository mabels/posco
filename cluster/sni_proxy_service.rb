module SniProxy
  class Service
    include Construqt::Util::Chainable
    attr_reader :name
    attr_accessor :services
    chainable_attr_value :server_iface, nil
    def initialize(name)
      @name = name
    end
    def completed_host(host)
      return unless host.docker_deploy
      puts "SNI>>>>>>>>>#{host.name}"
      host.docker_deploy.app_start_script("exec /usr/sbin/sniproxy -f")
    end
  end

  module Renderer
    module Nixian
      class Ubuntu
        DIRECTORY = File.dirname(__FILE__)

        def initialize(service)
          @service = service
        end


        def interfaces(host, ifname, iface, writer, family = nil)
          return unless iface.address
          puts "#{@service.name} #{host.name} #{ifname}"
          host.result.add(SniProxy::Service,
              Construqt::Util.render(binding, "sniproxy.conf.erb"),
              Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::UNREF),
              "/etc", "sniproxy.conf")
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
