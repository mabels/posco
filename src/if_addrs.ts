
import AsJson from './as_json';
import IPAddress from 'ipaddress';

 export class RouteVia implements AsJson {
  public dest: IPAddress;
  public via: IPAddress;
  public constructor() {
  }

  public static parse(dest: IPAddress, via: IPAddress) : RouteVia {
    if (via == null || dest == null) {
      return null;
    }
    let ret = new RouteVia();
    ret.dest = dest;
    ret.via = via;
    return ret;
  }
  public asJson() : Object {
    return {
      "dest": this.dest.to_string(),
      "via": this.via.to_string()
    }
  }
  public static fromJson(val: any) : RouteVia {
    let rv = new RouteVia();
    rv.dest = IPAddress.parse(val["dest"]);
    rv.via = IPAddress.parse(val["via"]);
    return rv;
  }
}

const enum ProtoFamily { AF_INET, AF_INET6 };

export class IfAddrs implements AsJson {
  public mtu: Number = 1360;
  public remoteAddress : IPAddress;
  public dests: IPAddress[] = [];
  public addrs: IPAddress[] = [];
  public routes: RouteVia[] = [];


  public getDests() : IPAddress[] { return this.dests; }
  public setDests(dests: IPAddress[]) : IfAddrs { 
    this.dests = dests; 
    return this;
  }
  public addDest(dest: IPAddress) : IfAddrs {
    if (!dest) {
      return null;
    }
    this.dests.push(dest);
    return this;
  }

  public getAddrs() : IPAddress[] { return this.addrs; }
  public getRoutes() : RouteVia[] { return this.routes; }

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
  public addAddr(addr: IPAddress) : IfAddrs {
    if (!addr) {
      return null;
    }
    this.addrs.push(addr);
    return this;
  }
  public addRoute(route: RouteVia) : IfAddrs {
    if (!route) {
      return null;   
    }
    this.routes.push(route);
    return this;
  }
  public asCommands(dev: string) : string {
    let ret = Array<String>();
    this.addrs.forEach((addr) => {
      ret.push("ip addr add " + addr.to_string() + " dev " + dev);
    });
    this.routes.forEach((route) => {
     	ret.push("ip route add " + route.dest.to_string() + " via " + route.via.to_s() + " dev " + dev);
    })
    ret.push("ip link set dev " + dev + " mtu " + this.mtu + " up");
    return ret.join("\n");
  }

  public asJson() : Object {
    return {
      "mtu" : this.mtu,
      "remoteAddress" : this.remoteAddress&&this.remoteAddress.to_s(),
      "dests" : this.dests.map(i => i.to_s()),
      "addrs" : this.addrs.map(i => i.to_string()),
      "routes" : this.routes.map(i => i.asJson())
    }
  }

  public static fromJson(obj: any) : IfAddrs  {
    let ret = new IfAddrs();
    ret.mtu = obj['mtu'];
    ret.remoteAddress = obj['remoteAddress'];
    if (obj['dests']) {
      if (!ret.setDests(obj['dests'].map((i:string) => IPAddress.parse(i)))) {
        console.error("dest not valid");
        return null;
      }
    }
    for (let addr of obj['addrs']) {
      if (!ret.addAddr(IPAddress.parse(addr))) {
        console.error("not valid addr:", addr);
        return null;
      }
    }
    for (let route of obj['routes']||[]) {
      let rv = RouteVia.fromJson(route);
      if (!rv) {
        console.error("not valid route:", route);
        return null;
      }
      ret.addRoute(rv);
    }
    return ret;
  }


}

