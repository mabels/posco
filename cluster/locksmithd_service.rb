module LockSmithd
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
      pbuilder.packages.register(LockSmithd::Service)
    end

    def build_url(host, port)
      throw "build url missing ipv6" unless host.interfaces['eth0'].address.first_ipv6
      #"https://[#{host.interfaces['eth0'].address.first_ipv6}]:#{port}"
      "https://#{host.fqdn}:#{port}"
    end

    def write_locksmithd_start_sh(result, host, locksmithd_s)
      locksmithd = self
      result.add(LockSmithd::Service, Construqt::Util.render(binding, 'locksmithd_startup.sh.erb'),
                      Construqt::Resources::Rights.root_0600(LockSmithd::Service),
                      "etc", "locksmithd", "start.sh")
    end

    def write_my_cert(result, host)
      domainname = host.fqdn
      cert_pkt = host.region.network.cert_store.find_package(domainname)
      result.add(LockSmithd::Service, cert_pkt.certs.map{|i|i.content}.join("\n"),
                      Construqt::Resources::Rights.root_0600(LockSmithd::Service),
                      "etc", "letsencrypt", "live", domainname, "cert.pem")
      result.add(LockSmithd::Service, cert_pkt.cacerts.map{|i|i.content}.join("\n"),
                      Construqt::Resources::Rights.root_0600(LockSmithd::Service),
                      "etc", "letsencrypt", "live", domainname, "fullchain.pem")
      result.add(LockSmithd::Service, cert_pkt.keys.first.content,
                      Construqt::Resources::Rights.root_0600(LockSmithd::Service),
                      "etc", "letsencrypt", "live", domainname, "privkey.pem")
    end

    # /usr/bin/docker run \
    #   --name <%= host.fqdn %> \
    #   --net host \
    #   -v /var/lib/locksmithd/data/<%= host.fqdn %>:/var/lib/locksmithd/data/<%= host.fqdn %>
    #   --trusted-ca-file /etc/locksmithd/client-trusted-cas.pem
    #   --peer-trusted-ca-file /etc/locksmithd/peers-trusted-cas.pem
    #   /etc/letsencrypt/live/<%= host.fqdn %>
    #

    def write_locksmithd_cas(result, host, fname, locksmithd_s)
      result.add(LockSmithd::Service, locksmithd_s.map do |h|
        domainname = h.fqdn
        cert_pkt = host.region.network.cert_store.find_package(domainname)
        cert_pkt.certs.first.content
      end.join("\n")+
      host.region.network.cert_store.find_package(locksmithd_s.first.fqdn).cacerts.map{|i|i.content}.join("\n"),
      Construqt::Resources::Rights.root_0600(LockSmithd::Service),
      "etc", "locksmithd", fname)
    end

    def build_config_host
      #return unless iface.address
      result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
      peers_locksmithd_s = Construqt::Tags.find("ETCD_S").map{|i| i.container.host }.sort{|a,b| a.name<=>b.name}.uniq
      client_locksmithd_s = (Construqt::Tags.find("ETCD_CLIENTS").map{|i| i.container.host } + peers_locksmithd_s).sort{|a,b| a.name<=>b.name}.uniq
      #puts "#{@service.name} #{host.name} #{ifname} #{peers_locksmithd_s.map{|i| i.name }} #{client_locksmithd_s.map{|i| i.name }}"
      write_locksmithd_cas(result, host, "peers-trusted-cas.pem", peers_locksmithd_s)
      write_locksmithd_cas(result, host, "client-trusted-cas.pem", client_locksmithd_s)
      write_my_cert(result, host)
      write_locksmithd_start_sh(result, host, peers_locksmithd_s)
      #myhostname = #{iface.host.name}
      #mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
      #MAINCF
    end

    def post_interfaces
      up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
      up_downer.add(@host, Taste::Entity.new())
    end
  end

  module Taste
    class Entity
    end

    class File
      def on_add(ud, taste, iface, me)
        #binding.pry
        fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkApplicationUd::OncePerHost)
        fsrv.up("/bin/sh /etc/locksmithd/start.sh")
        fsrv.down("/bin/sh /etc/locksmithd/stop.sh")
      end

      def activate(ctx)
        #binding.pry
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
  #           cps.register(LockSmithd::Service).add('locksmithd')
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

  #         def write_locksmithd_start_sh(host, locksmithd_s)
  #           locksmithd = self
  #           host.result.add(LockSmithd::Service, Construqt::Util.render(binding, 'locksmithd_startup.sh.erb'),
  #             Construqt::Resources::Rights.root_0600(LockSmithd::Service),
  #             "etc", "locksmithd", "start.sh")
  #         end

  #
  #
  #         def write_my_cert(host)
  #           domainname = host.fqdn
  #           cert_pkt = host.region.network.cert_store.find_package(domainname)
  #           host.result.add(LockSmithd::Service, cert_pkt.cert.content,
  #             Construqt::Resources::Rights.root_0600(LockSmithd::Service),
  #             "etc", "letsencrypt", "live", domainname, "cert.pem")
  #           host.result.add(LockSmithd::Service, cert_pkt.cacerts.map{|i|i.content}.join("\n"),
  #             Construqt::Resources::Rights.root_0600(LockSmithd::Service),
  #             "etc", "letsencrypt", "live", domainname, "fullchain.pem")
  #           host.result.add(LockSmithd::Service, cert_pkt.key.content,
  #             Construqt::Resources::Rights.root_0600(LockSmithd::Service),
  #             "etc", "letsencrypt", "live", domainname, "privkey.pem")
  #         end

  #           # /usr/bin/docker run \
  #           #   --name <%= host.fqdn %> \
  #           #   --net host \
  #           #   -v /var/lib/locksmithd/data/<%= host.fqdn %>:/var/lib/locksmithd/data/<%= host.fqdn %>
  #           #   --trusted-ca-file /etc/locksmithd/client-trusted-cas.pem
  #           #   --peer-trusted-ca-file /etc/locksmithd/peers-trusted-cas.pem
  #           #   /etc/letsencrypt/live/<%= host.fqdn %>
  #           #
  #
  #         def write_locksmithd_cas(host, fname, locksmithd_s)
  #           host.result.add(LockSmithd::Service, locksmithd_s.map do |h|
  #             domainname = h.fqdn
  #             cert_pkt = host.region.network.cert_store.find_package(domainname)
  #             cert_pkt.cert.content
  #           end.join("\n"),
  #           Construqt::Resources::Rights.root_0600(LockSmithd::Service),
  #           "etc", "locksmithd", fname)
  #         end

  #
  #         def interfaces(host, ifname, iface, writer, family = nil)
  #           return unless iface.address
  #           peers_locksmithd_s = Construqt::Tags.find("ETCD_S").map{|i| i.container.host }.sort{|a,b| a.name<=>b.name}.uniq
  #           client_locksmithd_s = (Construqt::Tags.find("ETCD_CLIENTS").map{|i| i.container.host } + peers_locksmithd_s).sort{|a,b| a.name<=>b.name}.uniq
  #           puts "#{@service.name} #{host.name} #{ifname} #{peers_locksmithd_s.map{|i| i.name }} #{client_locksmithd_s.map{|i| i.name }}"
  #           write_locksmithd_cas(host, "peers-trusted-cas.pem", peers_locksmithd_s)
  #           write_locksmithd_cas(host, "client-trusted-cas.pem", client_locksmithd_s)
  #           write_my_cert(host)
  #           write_locksmithd_start_sh(host, peers_locksmithd_s)
  #           #myhostname = #{iface.host.name}
  #           #mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
  #           #MAINCF
  #         end

  #       end

  #     end

  #   end

  # end

  # Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(LockSmithd::Service, LockSmithd::Renderer::Nixian::Ubuntu)
end
