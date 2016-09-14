import { assert } from 'chai';
import * as Mocha from 'mocha';
import {IfAddrs,RouteVia} from "../src/if_addrs";
import IPAddress from 'ipaddress';

describe('IfAddrs', () => {

  it("IsUsable", () => {
    let ia = new IfAddrs();
    ia.addAddr(IPAddress.parse("10.1.0.1/24"));
    assert.isNotNull(ia.addAddr(IPAddress.parse("10.2.0.1/24")), "ia.addAddr failed");
    assert.isNull(ia.addAddr(IPAddress.parse("256.2.0.1/24")), "ia.addAddr failed");
    assert.isNotNull(ia.addRoute(RouteVia.parse(IPAddress.parse("172.16.0.1/24"), 
      IPAddress.parse("172.16.0.254"))));

    assert.isNull(ia.addDest(IPAddress.parse("172.316.0.1/24")));
    assert.isNotNull(ia.addDest(IPAddress.parse("172.16.0.1/24"))); 

    assert.isNotNull(ia.addRoute(RouteVia.parse(IPAddress.parse("172.17.0.1/24"), 
      IPAddress.parse("172.17.0.254"))), "ia.addRoute 1 failed");
    assert.isNull(ia.addRoute(RouteVia.parse(IPAddress.parse("300.17.0.1/24"), 
      IPAddress.parse("172.17.0.254"))), "ia.addRoute 2 failed");
    assert.isNull(ia.addRoute(RouteVia.parse(IPAddress.parse("300.17.0.1/24"), 
      IPAddress.parse("172.17.0.254/23"))), "ia.addRoute 3 failed"); 
    assert.isNull(ia.addRoute(RouteVia.parse(IPAddress.parse("300.17.0.1/24"), 
      IPAddress.parse("172.17.0.354"))), "ia.addRoute 4 failed");
    let ret = ia.asCommands("DEV");
    let ref = ["ip addr add 10.1.0.1/24 dev DEV",
               "ip addr add 10.2.0.1/24 dev DEV",
               "ip route add 172.16.0.1/24 via 172.16.0.254 dev DEV",
               "ip route add 172.17.0.1/24 via 172.17.0.254 dev DEV",
               "ip link set dev DEV mtu 1360 up"].join("\n");
    assert.equal(ret, ref, "wrong string");           
    let objIa = JSON.stringify(ia.asJson());
    let other = JSON.parse(objIa);
    let otherIa = IfAddrs.fromJson(other);
    // console.log("other:", other);
    // console.log("otherIa:", otherIa);
    assert.equal(objIa, JSON.stringify(otherIa.asJson()));
  });
});
