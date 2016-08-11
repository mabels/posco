/// <reference path="../typings/mocha/mocha.d.ts" />
import { assert } from 'chai';
import {IfAddrs,RouteVia} from "../src/if_addrs";

describe('IfAddrs', () => {
  it("IsValidWithPrefix", () => {
    let testIsValidWithPrefix : { [id: string]: boolean } = {
      "": false,
      "a.b.c.d": false,
      "300.200.200.200": false,
      "200.200.200.200": true,
      "200::200:200:200": true,
      "/": false,
      "/17": false,
      "/a7": false,
      "200.200.200.200/": true,
      "200.200.200.200/a7": false,
      "200.200.200.200/7": true,
      "200.200.200.200/-1": false,
      "200.200.200.200/33": false,
      "zoo::200/": false,
      "200:200:200::200/a7": false,
      "200:200:200::200/77": true,
      "200:200:200::200/-1": false,
      "200:200:200::200/129": false
    };
    for (let key in testIsValidWithPrefix) {
      let val = testIsValidWithPrefix[key];
      assert.equal(val, IfAddrs.isValidWithPrefix(key), "key:["+key+"] val="+val);
    }
  });

  it("IsValidWithoutPrefix", () => {
    let testIsValidWithoutPrefix : { [id: string] : boolean } = {
      "": false,
      "/": false,
      "/a7": false,
      "/17": false,
      "1.2.3.4/17": false,
      "1:2:3::4/17": false,
      "300.2.3.4": false,
      "1:zoo:3::4": false,
      "1.2.3.4": true,
      "1:2:3::4": true 
    };
    for (let key in testIsValidWithoutPrefix) {
      let val = testIsValidWithoutPrefix[key];
      assert.equal(val, IfAddrs.isValidWithoutPrefix(key), key);
    }
  });


  it("IsUsable", () => {
    let ia = new IfAddrs();
    ia.addAddr("10.1.0.1/24");
    assert.equal(true, ia.addAddr("10.2.0.1/24"), "ia.addAddr failed");
    assert.equal(false, ia.addAddr("256.2.0.1/24"), "ia.addAddr failed");
    ia.addRoute(new RouteVia("172.16.0.1/24", "172.16.0.254"));
    assert.equal(true, ia.addRoute(new RouteVia("172.17.0.1/24", "172.17.0.254")), "ia.addRoute 1 failed");
    assert.equal(false, ia.addRoute(new RouteVia("300.17.0.1/24", "172.17.0.254")), "ia.addRoute 2 failed");
    assert.equal(false, ia.addRoute(new RouteVia("300.17.0.1/24", "172.17.0.254/23")), "ia.addRoute 3 failed");
    assert.equal(false, ia.addRoute(new RouteVia("300.17.0.1/24", "172.17.0.354")), "ia.addRoute 4 failed");
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
    assert.equal(objIa, JSON.stringify(otherIa));
  });
});
