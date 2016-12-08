

#10607  doctl compute droplet create test --size 512mb --image coreos-beta --region fra1 --ssh-keys af:bd:ed:74:85:81:67:5d:39:7e:e6:50:2b:3e:3a:ff --enable-ipv6
#10608  doctl compute droplet list
#10610  doctl compute droplet delete 33956879

module DigitalOcean
  DIRECTORY = File.dirname(__FILE__)
  class Service
    include Construqt::Util::Chainable
    chainable_attr_value :size
    chainable_attr_value :image
    chainable_attr_value :region
    chainable_attr_value :ssh_keys
    chainable_attr_value :enable_ipv6
    def initialize
      @size = "512mb"
      @image = "coreos-beta"
      @region = "fra1"
      @ssh_keys = [""]
      @enable_ipv6 = false
    end
    def self.from(p)
      Service.new
        .size(p['size'])
        .image(p['image'])
        .region(p['region'])
        .ssh_keys(p['ssh_keys'])
        .enable_ipv6(p['enable_ipv6'])
    end
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
      result.add(self,
                 Construqt::Util.render(binding, "create-digital-ocean-droplet.rb.erb"),
                 Construqt::Resources::Rights.root_0755,
                 "create-digital-ocean-droplet.rb")
    end
  end

  class Factory
    attr_reader :machine
    def start(service_factory)
      @machine ||= service_factory.machine
        .service_type(Service)
        .require(Construqt::Flavour::Nixian::Services::Result::Service)
    end

    def produce(host, srv_inst, ret)
      Action.new(host, srv_inst)
    end
  end
end
