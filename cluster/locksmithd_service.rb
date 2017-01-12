module LockSmithd
  DIRECTORY = File.dirname(__FILE__)
  class Service
  end

  class Action
    attr_reader :host
    def initialize(host)
      @host = host
    end

    def activate(context)
      @context = context
    end

    def build_config_host
      result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
      Etcd::Action.write_my_cert(result, @host)
    end

    def post_interfaces
      ess = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost
      ess.get("locksmithd.service") do |srv|
        srv.skip_content
        srv.drop_in("20-etcd-binding.conf") do |dropin|
          dropin.environment("REBOOT_STRATEGY=etcd-lock")
          dropin.environment("LOCKSMITHD_ETCD_CAFILE=/etc/letsencrypt/live/#{host.fqdn}/fullchain.pem")
          dropin.environment("LOCKSMITHD_ETCD_CERTFILE=/etc/letsencrypt/live/#{host.fqdn}/cert.pem")
          dropin.environment("LOCKSMITHD_ETCD_KEYFILE=/etc/letsencrypt/live/#{host.fqdn}/privkey.pem")
          etcd_s = Construqt::Tags.find("ETCD_S").map{|i| i.container.host }.sort{|a,b| a.name<=>b.name}.uniq
          etcd_s_urls = etcd_s.map{|host| Etcd::Action.build_url(host, 2381) }.join(",")
          dropin.environment("LOCKSMITHD_ENDPOINT=#{etcd_s_urls}")
        end
      end
    end
  end

  class Factory
    attr_reader :machine
    def start(service_factory)
      @machine ||= service_factory.machine
        .service_type(Service)
        .require(Construqt::Flavour::Nixian::Services::Result::Service)
        .require(Construqt::Flavour::Nixian::Services::EtcSystemdService::Service)
    end

    def produce(host, srv_inst, ret)
      Action.new(host)
    end
  end
end
