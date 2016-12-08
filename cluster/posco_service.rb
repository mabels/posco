module Posco
  class Service
    include Construqt::Util::Chainable
    chainable_attr_value :server_iface, nil
    chainable_attr_value :domains, nil
  end

  class Action
  end

  class Factory
    attr_reader :machine
    def start(service_factory)
      @machine ||= service_factory.machine
        .service_type(Service)
    end
    def produce(host, srv_inst, ret)
      Action.new
    end
  end

end
