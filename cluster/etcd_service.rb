module Etcd
  DIRECTORY = File.dirname(__FILE__)
  class Service
    include Construqt::Util::Chainable
    chainable_attr_value :server_iface, nil
    chainable_attr_value :domains, nil
  end

  class Action
    attr_reader :host
    def initialize(host)
      @host = host
    end

    def activate(context)
      @context = context
      pbuilder = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::Packager::OncePerHost
      pbuilder.packages.register(Etcd::Service)
    end

    def build_url(host, port)
      throw "build url missing ipv6" unless host.interfaces['eth0'].address.first_ipv6
      "https://[#{host.interfaces['eth0'].address.first_ipv6}]:#{port}"
    end

    def write_etcd_start_sh(result, host, etcd_s)
      etcd = self
      result.add(Etcd::Service, Construqt::Util.render(binding, 'etcd_startup.sh.erb'),
                      Construqt::Resources::Rights.root_0600(Etcd::Service),
                      "etc", "etcd", "start.sh")
    end

    def write_my_cert(result, host)
      domainname = host.fqdn
      cert_pkt = host.region.network.cert_store.find_package(domainname)
      result.add(Etcd::Service, cert_pkt.cert.content,
                      Construqt::Resources::Rights.root_0600(Etcd::Service),
                      "etc", "letsencrypt", "live", domainname, "cert.pem")
      result.add(Etcd::Service, cert_pkt.cacerts.map{|i|i.content}.join("\n"),
                      Construqt::Resources::Rights.root_0600(Etcd::Service),
                      "etc", "letsencrypt", "live", domainname, "fullchain.pem")
      result.add(Etcd::Service, cert_pkt.key.content,
                      Construqt::Resources::Rights.root_0600(Etcd::Service),
                      "etc", "letsencrypt", "live", domainname, "privkey.pem")
    end

    # /usr/bin/docker run \
    #   --name <%= host.fqdn %> \
    #   --net host \
    #   -v /var/lib/etcd/data/<%= host.fqdn %>:/var/lib/etcd/data/<%= host.fqdn %>
    #   --trusted-ca-file /etc/etcd/client-trusted-cas.pem
    #   --peer-trusted-ca-file /etc/etcd/peers-trusted-cas.pem
    #   /etc/letsencrypt/live/<%= host.fqdn %>
    #

    def write_etcd_cas(result, host, fname, etcd_s)
      result.add(Etcd::Service, etcd_s.map do |h|
        domainname = h.fqdn
        cert_pkt = host.region.network.cert_store.find_package(domainname)
        cert_pkt.cert.content
      end.join("\n"),
      Construqt::Resources::Rights.root_0600(Etcd::Service),
      "etc", "etcd", fname)
    end

    def build_config_host
      #return unless iface.address
      result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
      peers_etcd_s = Construqt::Tags.find("ETCD_S").map{|i| i.container.host }.sort{|a,b| a.name<=>b.name}.uniq
      client_etcd_s = (Construqt::Tags.find("ETCD_CLIENTS").map{|i| i.container.host } + peers_etcd_s).sort{|a,b| a.name<=>b.name}.uniq
      #puts "#{@service.name} #{host.name} #{ifname} #{peers_etcd_s.map{|i| i.name }} #{client_etcd_s.map{|i| i.name }}"
      write_etcd_cas(result, host, "peers-trusted-cas.pem", peers_etcd_s)
      write_etcd_cas(result, host, "client-trusted-cas.pem", client_etcd_s)
      write_my_cert(result, host)
      write_etcd_start_sh(result, host, peers_etcd_s)
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
        binding.pry
        fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkApplicationUd::OncePerHost)
        fsrv.up("/etc/etcd/start.sh")
        fsrv.down("/etc/etcd/stop.sh")
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
        .require(Construqt::Packages::Builder)
        .activator(Construqt::Flavour::Nixian::Services::UpDowner::Activator.new
        .entity(Taste::Entity)
        .add(Construqt::Flavour::Nixian::Tastes::File::Factory, Taste::File))
    end

    def produce(host, srv_inst, ret)
      Action.new(host)
    end
  end

  #   module Renderer
  #     module Nixian
  #       class Ubuntu
  #         def self.add_component(cps)
  #           cps.register(Etcd::Service).add('etcd')
  #         end

  #
  #         DIRECTORY = File.dirname(__FILE__)
  #         def initialize(service)
  #           @service = service
  #         end

  #
  #         def build_url(host, port)
  #           throw "build url missing ipv6" unless host.interfaces['eth0'].address.first_ipv6
  #           "https://[#{host.interfaces['eth0'].address.first_ipv6}]:#{port}"
  #         end

  #         def write_etcd_start_sh(host, etcd_s)
  #           etcd = self
  #           host.result.add(Etcd::Service, Construqt::Util.render(binding, 'etcd_startup.sh.erb'),
  #             Construqt::Resources::Rights.root_0600(Etcd::Service),
  #             "etc", "etcd", "start.sh")
  #         end

  #
  #
  #         def write_my_cert(host)
  #           domainname = host.fqdn
  #           cert_pkt = host.region.network.cert_store.find_package(domainname)
  #           host.result.add(Etcd::Service, cert_pkt.cert.content,
  #             Construqt::Resources::Rights.root_0600(Etcd::Service),
  #             "etc", "letsencrypt", "live", domainname, "cert.pem")
  #           host.result.add(Etcd::Service, cert_pkt.cacerts.map{|i|i.content}.join("\n"),
  #             Construqt::Resources::Rights.root_0600(Etcd::Service),
  #             "etc", "letsencrypt", "live", domainname, "fullchain.pem")
  #           host.result.add(Etcd::Service, cert_pkt.key.content,
  #             Construqt::Resources::Rights.root_0600(Etcd::Service),
  #             "etc", "letsencrypt", "live", domainname, "privkey.pem")
  #         end

  #           # /usr/bin/docker run \
  #           #   --name <%= host.fqdn %> \
  #           #   --net host \
  #           #   -v /var/lib/etcd/data/<%= host.fqdn %>:/var/lib/etcd/data/<%= host.fqdn %>
  #           #   --trusted-ca-file /etc/etcd/client-trusted-cas.pem
  #           #   --peer-trusted-ca-file /etc/etcd/peers-trusted-cas.pem
  #           #   /etc/letsencrypt/live/<%= host.fqdn %>
  #           #
  #
  #         def write_etcd_cas(host, fname, etcd_s)
  #           host.result.add(Etcd::Service, etcd_s.map do |h|
  #             domainname = h.fqdn
  #             cert_pkt = host.region.network.cert_store.find_package(domainname)
  #             cert_pkt.cert.content
  #           end.join("\n"),
  #           Construqt::Resources::Rights.root_0600(Etcd::Service),
  #           "etc", "etcd", fname)
  #         end

  #
  #         def interfaces(host, ifname, iface, writer, family = nil)
  #           return unless iface.address
  #           peers_etcd_s = Construqt::Tags.find("ETCD_S").map{|i| i.container.host }.sort{|a,b| a.name<=>b.name}.uniq
  #           client_etcd_s = (Construqt::Tags.find("ETCD_CLIENTS").map{|i| i.container.host } + peers_etcd_s).sort{|a,b| a.name<=>b.name}.uniq
  #           puts "#{@service.name} #{host.name} #{ifname} #{peers_etcd_s.map{|i| i.name }} #{client_etcd_s.map{|i| i.name }}"
  #           write_etcd_cas(host, "peers-trusted-cas.pem", peers_etcd_s)
  #           write_etcd_cas(host, "client-trusted-cas.pem", client_etcd_s)
  #           write_my_cert(host)
  #           write_etcd_start_sh(host, peers_etcd_s)
  #           #myhostname = #{iface.host.name}
  #           #mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
  #           #MAINCF
  #         end

  #       end

  #     end

  #   end

  # end

  # Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(Etcd::Service, Etcd::Renderer::Nixian::Ubuntu)
end
