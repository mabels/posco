module Dns
  class Service
    include Construqt::Util::Chainable
    attr_reader :name, :nss
    attr_accessor :services
    chainable_attr_value :server_iface, nil
    chainable_attr_value :domains, nil
    def initialize(name, nss)
      @name = name
      @nss = nss
    end
    def self.add_component(cps)
      cps.register(Dns::Service).add('bind9')
    end
    def completed_host(host)
      return unless host.docker_deploy
      puts "BIND>>>>>>>>>#{host.name}"
      host.docker_deploy.app_start_script("exec /usr/sbin/named -f -g")
    end
    def create
      self.clone
    end
  end

  module Renderer
    module Nixian
      class Ubuntu
	DIRECTORY = File.dirname(__FILE__)

        def initialize(service)
          @service = service
        end

        def write_named_conf_local(host, result, zone)
            result.add(Dns::Service,
            Construqt::Util.render(binding, "dns.named.conf.local.erb"),
            Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::UNREF),
            "/etc/bind", "named.conf.local")
        end

        def write_zone_file(host, result, ns, zone)
            ['soa', 'ns', 'zone', 'add'].each do |i|
              result.add(Dns::Service,
              Construqt::Util.render(binding, "dns.#{i}.file.erb"),
              OpenStruct.new(:right => "0644", :owner => "bind", :component => Construqt::Resources::Component::UNREF),
              "/var/lib/bind/", "#{zone.name}.#{i}")
            end
            result.add(Dns::Service, "; rumpf zone file\n" + zone.content,
              OpenStruct.new(:right => "0644", :owner => "bind", :component => Construqt::Resources::Component::UNREF),
              "/var/lib/bind/", "#{zone.name}.skel")
        end

        def interfaces(host, ifname, iface, writer, family = nil)
          return unless iface.address
          @service.nss.each do |ns|
            ns.zones.each do |zone|
              write_named_conf_local(host, host.result, zone)
              write_zone_file(host, host.result, ns, zone)
            end
          end
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
Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(Dns::Service, Dns::Renderer::Nixian::Ubuntu)
