module SniProxy
  DIRECTORY = File.dirname(__FILE__)
  class Service
    include Construqt::Util::Chainable
    chainable_attr_value :server_iface, nil
    chainable_attr_value :domains, nil
  end

  class Action
    attr_reader :host
    def initialize(host, service)
      @host = host
      @service = service
    end

    def activate(context)
      @context = context
    end
    def build_config_host
      result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
      result.add(SniProxy::Service,
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

  module Taste
    class Entity
    end

    class File
      def on_add(ud, taste, iface, me)
        fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkApplicationUd::OncePerHost)
        fsrv.up("/usr/sbin/sniproxy -f")
        fsrv.down("pkill sinproxy")
      end

      def activate(ctx)
        @context = ctx
        self
      end
    end
  end

  class Factory
    attr_reader :machine
    def start(service_factory)
      @machine ||= service_factory.machine
        .service_type(Service)
        .require(Construqt::Flavour::Nixian::Services::EtcNetworkApplicationUd::Service)
        .require(Construqt::Flavour::Nixian::Services::UpDowner::Service)
        .require(Construqt::Flavour::Nixian::Services::Result::Service)
        .activator(Construqt::Flavour::Nixian::Services::UpDowner::Activator.new
          .entity(Taste::Entity)
          .add(Construqt::Flavour::Nixian::Tastes::File::Factory, Taste::File))
    end

    def produce(host, srv_inst, ret)
      Action.new(host, srv_inst)
    end
  end
end

#        def interfaces(host, ifname, iface, writer, family = nil)
#          return unless iface.address
#          puts "#{@service.name} #{host.name} #{ifname}"
#          host.result.add(SniProxy::Service,
#              Construqt::Util.render(binding, "sniproxy.conf.erb"),
#              Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::UNREF),
#              "/etc", "sniproxy.conf")
#          ## #{@service.get_server_iface.host.name} #{@service.get_server_iface.address.first_ipv4}
#          #inet_protocols = all
#          #myhostname = #{iface.host.name}
#          #mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
#          #MAINCF
#        end

#      end

#    end

#  end

#end

#Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(SniProxy::Service, SniProxy::Renderer::Nixian::Ubuntu)
