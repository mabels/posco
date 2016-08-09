
 export class RouteVia {
  public dest: string;
  public via: string;
  public isValid() : boolean {
    return IfAddrs.isValidWithPrefix(this.dest) &&
          IfAddrs.isValidWithoutPrefix(this.via);
  }
  public asJson() : Object {
    return {
      "dest": this.dest,
      "via": this.via
    }
  }
  public static fromJson(val: any) : RouteVia {
    let rv = new RouteVia();
    rv.dest = val["dest"];
    rv.via = val["via"];
    return rv;
  }
}

const enum ProtoFamily { AF_INET, AF_INET6 };

export class IfAddrs {
  public mtu: Number = 1360;
  public addrs: Array<String> = [];
  public routes: Array<RouteVia> = [];

  static splitPrefix(addr: string) : string[] {
    let slash = addr.split("/");
    if (slash.length == 1) {
      return [slash[0], ""];
    }
    return [slash[0], slash[1]];
  }
  static isPrefixValid(af: ProtoFamily, sPrefix: string) : boolean {
    if (sPrefix.length == 0) {
      return true;
    }
    let prefix = parseInt(sPrefix, 10);
    if (isNaN(prefix)) {
      return false;
    }
    if (af == ProtoFamily.AF_INET && 0 <= prefix && prefix <= 32) {
      return true;
    }
    if (af == ProtoFamily.AF_INET6 && 0 <= prefix && prefix <= 128) {
      return true;
    }
    return false;
  }

  public static isValidWithoutPrefix(addr: string) : boolean {
    let slash = addr.split("/");
    if (slash.length == 1) {
      return false;
    }
    return IfAddrs.isValidWithPrefix(addr);
  }
  public static isValidWithPrefix(addr: string) : boolean {
    // let sp = IfAddrs.splitPrefix(addr);
    // if (inet_pton(AF_INET, sp.first.c_str(), &ipv4_dst) == 1) {
    //   return isPrefixValid(AF_INET, sp.second);
    // }
    // struct in6_addr ipv6_dst;
    // if (inet_pton(AF_INET6, sp.first.c_str(), &ipv6_dst) == 1) {
    //   return isPrefixValid(AF_INET6, sp.second);
    // }
    return false;
  }

  public getAddrs() : Array<String> { return this.addrs; }
  public getRoutes() : Array<RouteVia> { return this.routes; }

  public setMtu(_mtu: Number) {
     this.mtu = _mtu;
  }
  public getMtu() : Number {
    return this.mtu;
  }

  public isEcho() : boolean {
    // LOG(INFO) << addrs.size() << ":" << addrs.empty();
    // LOG(INFO) << asCommands("isEcho");
    return this.addrs.length == 0;
  }
  public addAddr(addr: string) : boolean {
    if (!IfAddrs.isValidWithPrefix(addr)) {
      return false;
    }
    this.addrs.push(addr);
    return true;
  }
  public addRoute(route: RouteVia) {
    if (!route.isValid()) {
      return false;
    }
    this.routes.push(route);
    return true;
  }
  public asCommands(dev: string) : string {
    let ret = Array<String>();
    this.addrs.forEach((addr) => {
      ret.push("ip addr add " + addr + " dev " + dev);
    });
    this.routes.forEach((route) => {
     	ret.push("ip route add " + route.dest + " via " + route.via + " dev " + dev);
    })
    ret.push("ip link set dev " + dev + " mtu " + this.mtu + " up");
    return ret.join("\n");
  }

  public asJson() : Object {
    return {
      "mtu" : this.mtu,
      "addrs" : this.addrs,
      "routes" : this.routes
    }
  }

  public static fromJson(obj: any) : IfAddrs  {
    let ret = new IfAddrs();
    ret.mtu = obj['mtu'];
    ret.addrs = obj['addrs'];
    ret.routes = obj['routes'];
    return ret;
  }


}
