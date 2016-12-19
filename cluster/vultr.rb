# Download latest Release from https://github.com/JamesClonk/vultr/releases
# Untar it and move the vultr executable to /usr/local/bin/

# set your Vultr API Key
# $ export VULTR_API_KEY=<API KEY>

# Get the interesting Vultr Regions
#vultr regions
#DCID	NAME		CONTINENT	COUNTRY		STATE	STORAGE		CODE
#7	Amsterdam	Europe		NL			false		AMS
#1	New Jersey	North America	US		NJ	true		EWR
#5	Los Angeles	North America	US		CA	false		LAX
#9	Frankfurt	Europe		DE			false		FRA

# Deploy a new etcbind from a snapshot
# $ vultr server create -n <SERVER_NAME> -r <REGION> -p 29 -o 164 --snapshot="c9f585152574f" --ipv6=true
# list all Servers
# $ vultr servers
# Delete a server
# $ vultr server delete <SERVER_SUBID> -f

module Vultr
  DIRECTORY = File.dirname(__FILE__)
  class Service
    include Construqt::Util::Chainable
    chainable_attr_value :plan
    chainable_attr_value :os
    chainable_attr_value :region
    chainable_attr_value :snapshot
    chainable_attr_value :enable_ipv6
    attr_reader :cluster_rb_directory
    def initialize
      @plan = "29"			# 768MB RAM, 15GB SSD, 1 TB BW
      @os = "164"			# Number for using a Snapshot
      @region = "9"			# Frankfurt
      @enable_ipv6 = true
      @snapshot = "c9f585152574f"	# CoreOS Beta Snapshot with all needed SSH Keys
      @cluster_rb_directory = File.dirname(__FILE__)
    end
    def self.from(p)
      Service.new
        .plan(p['plan'])
        .os(p['os'])
        .region(p['region'])
        .snapshot(p['snapshot'])
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
                 Construqt::Util.render(binding, "create-vultr-droplet.rb.erb"),
                 Construqt::Resources::Rights.root_0755,
                 "create-vultr-droplet.rb")
      result.add(self,
                 Construqt::Util.render(binding, "remove-vultr-droplet.rb.erb"),
                 Construqt::Resources::Rights.root_0755,
                 "remove-vultr-droplet.rb")
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
