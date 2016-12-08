class DnsZone
  attr_reader :name, :fname, :content
  def initialize(zname, fname, content)
    @name = zname
    @fname = fname
    @content = content
  end

  def self.load(fname)
    zname = File.basename(fname)[0..-(".static.zone".length + 1)]
    content = IO.read(fname)
    ret = DnsZone.new(zname, fname, content)
  end
end

class DnsZones
  def initialize
    @zones = {}
  end

  def names
    @zones.keys
  end

  def each(&block)
    @zones.values.each(&block)
  end

  def add(zone)
    @zones[zone.name] = zone
  end

  def self.load(path)
    ret = DnsZones.new
    Dir.glob(File.join(path,"*.static.zone")).each do|dname|
      next unless File.file?(dname)
      Construqt.logger.info "Reading Static Zone for #{File.basename(dname)}"
      ret.add(DnsZone.load(dname))
    end

    ret
  end
end

class NameServerSet
  attr_reader :zones
  def self.load(fname)
    js = JSON.parse(IO.read(fname))
    dz = DnsZones.load(fname[0..-(".json".length + 1)])
    NameServerSet.new(fname, js, dz)
  end

  def servers(&block)
    @cfg.each(&block)
  end

  def initialize(fname, cfg, dz)
    @cfg = cfg
    @fname = fname
    @zones = dz
  end

  def name
    File.basename(@fname)
  end
end

class NameServerSets

  def self.load(cfg)
    throw "config parameter dns path not set" unless cfg["path"]
    ret = NameServerSets.new
    Dir.glob(File.join(cfg["path"],"*.json")).each do|fname|
      next unless File.file?(fname)
      ret.add(NameServerSet.load(fname))
    end

    ret
  end

  def initialize
    @sets = {}
  end

  def each(&block)
    @sets.values.each(&block)
  end

  def add(nss)
    @sets[nss.name] = nss
  end

  def names
    @sets.values.map {|i|i.zones.names}.flatten
  end
end

module Dns
  DIRECTORY = File.dirname(__FILE__)
  class Service
    include Construqt::Util::Chainable
    attr_reader :name, :nss
    attr_accessor :services

    chainable_attr_value :server_iface, nil
    chainable_attr_value :domains, nil
    def initialize(fname)
      @name = name
      @nss = NameServerSets.load(fname)
    end
  end

  class Action
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
                   Construqt::Resources::Rights.create('bind', '0644'),
                   "/var/lib/bind/", "#{zone.name}.#{i}")
      end

      result.add(Dns::Service, "; rumpf zone file\n" + zone.content,
                 Construqt::Resources::Rights.create('bind', '0644'),
                 "/var/lib/bind/", "#{zone.name}.skel")
    end

    def activate(context)
      @context = context
    end
    def attach_host(host)
      @host = host
    end
    def build_config_host
      #return unless iface.address
      result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
      @service.nss.each do |ns|
        ns.zones.each do |zone|
          write_named_conf_local(host, result, zone)
          write_zone_file(host, result, ns, zone)
        end
      end
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
        fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkApplicationUd::OncePerHost)
        fsrv.up("/usr/sbin/named -f -g")
        fsrv.down("/usr/sbin/rndc stop")
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

    def add_component(cps)
      cps.register(Dns::Service).add('bind9')
    end


    def produce(host, srv_inst, ret)
      Action.new(srv_inst)
    end
  end
end
