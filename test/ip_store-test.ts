import { assert } from 'chai';
import * as Mocha from 'mocha';
// import {IfAddrs,RouteVia} from "../src/if_addrs";
import {IpStore,IpAssigned,IpEntry} from "../src/ip_store";
import IPAddress from 'ipaddress';

describe('IpStore', () => {
  it("findFree", () => {
    let ips = IpStore.fromJson({
        ipv4Range: [["192.168.176.100/24", "192.168.176.200/24"]],
        ipv6Range: [["fd00::100/112", "fd00::164/112"]],
        ipAssigned: new IpAssigned()
    });
    // console.log("ipstore:-1:", ips);
    ips.assignGateWay([IPAddress.parse("192.168.176.254/24"), IPAddress.parse("fd00::1/112")]);
    // console.log("ipstore:-2:", ips);
    let ipes : IpEntry[] = [];
    for(let i = 0; i <= 100; ++i) {
      // console.log("ipstore:-3:", i);
      let ipe = ips.findFree(null, null);
      ipes.push(ipe);
      // console.log("ipstore:-4:", i);
      let ipe_a = ipe.ifAddr.getAddrs().map(s => s.to_string());
      // console.log("ipstore:-5:", i, `192.168.176.${i+100}/24`, `fd00::${i+100}/112`);
      assert.deepEqual([ '192.168.176.254', 'fd00::1' ], IPAddress.to_s_vec(ipe.ifAddr.getDests()));
      assert.deepEqual([
        IPAddress.parse(`192.168.176.${i+100}/24`).to_string(),
        IPAddress.parse(`fd00::${(i+0x100).toString(16)}/112`).to_string()
      ], ipe_a);
    }
    let ff = ips.findFree(null, null);
    console.log(ff);
    assert.isNull(ff);
    let first = ipes.shift();
    let release = ips.release(first);
    assert.equal(first, release);
    let found = ips.findFree(null, null);
    // console.log("found:", found);
    assert.deepEqual(first.ifAddr.getAddrs(), found.ifAddr.getAddrs());
    assert.isNull(ips.findFree(null, null));
    // free one
    // find one != null
    // find one == null
  });
});
