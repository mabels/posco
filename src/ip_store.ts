// import PoscoContext from './posco_context';
import * as IfAddrs from './if_addrs';
import * as WebSocket from 'ws';
import * as Packet from './packet';
import * as fs from 'fs';
import {IPAddress, Crunchy, Ipv4, Ipv6} from 'ipaddress';

export class IpEntry {
    public ifAddr: IfAddrs.IfAddrs;
    public ws: WebSocket;
}

class IpRange {
    public start: IPAddress;
    public target: IPAddress;
    public static fromJson(obj: [string, string]): IpRange {
        let ir = new IpRange();
        ir.start = IPAddress.parse(obj[0]);
        if (!ir.start) {
            console.error("IpRange not failed", obj);
            return null;
        }
        ir.target = IPAddress.parse(obj[1]);
        if (!ir.target) {
            console.error("IpRange not failed", obj);
            return null;
        }
        if (ir.start.cmp(ir.target) >= 0) {
            console.error("IpRange not failed", obj);
            return null;
        }
        if (!ir.start.prefix.eq(ir.target.prefix)) {
            console.error("IpRange not failed", obj);
            return null;
        }
        if (!ir.start.network().includes(ir.target)) {
            console.error("IpRange not failed", obj);
            return null;
        }
        return ir;
    }

    public size(): Crunchy {
        return this.target.sub(this.start);
    }
}

export class IpAssigned {
    ipAssigned: { [id: string]: IpEntry } = {};
    fname: string;

    public static fromFile(fname: string): IpAssigned {
        let ret = new IpAssigned();
        ret.fname = fname;
        let buf = fs.readFileSync(ret.fname, 'utf8');
        if (!buf) {
            console.log("fromFile failed:", ret.fname);
            return null;
        }
        ret.ipAssigned = JSON.parse(buf);
        if (!ret.ipAssigned) {
            console.log("fromFile failed parse error:", ret.fname);
            return null;
        }
        return ret;
    }

    public is_assigned(ia: IPAddress): IpEntry {
        return this.ipAssigned[ia.to_s()];
    }

    public assign(ia: IPAddress, ie: IpEntry): IPAddress {
        if (this.is_assigned(ia)) {
            return null;
        }
        this.ipAssigned[ia.to_s()] = ie;
        return ia;
    }

    public release(ia: IPAddress): IPAddress {
        let s = ia.to_s();
        if (this.ipAssigned[s]) {
            delete this.ipAssigned[s];
            return ia;
        }
        return null;
    }

}


export class IpStore {
    // context: PoscoContext;
    // addrs: { [key: string]: IpEntry } = {};
    ipv4Range: IpRange[] = [];
    ipv6Range: IpRange[] = [];
    ipAssigned: IpAssigned;
    gateWays: IPAddress[] = [];

    constructor() {
        // this.context = context;
    }

    static toIpRangeArray(obj: any): IpRange[] {
        let ret: IpRange[] = [];
        if (!ret) {
            return ret;
        }
        for (let i = 0; i < obj.length; ++i) {
            let r = obj[i];
            ret.push(IpRange.fromJson([r[0], r[1]]));
        }
        return ret;
    }

    public static fromJson(obj: any): IpStore {
        let ret = new IpStore();
        // console.log("IpStore:", obj);
        ret.ipv4Range = IpStore.toIpRangeArray(obj.ipv4Range);
        ret.ipv6Range = IpStore.toIpRangeArray(obj.ipv6Range);
        if (!ret.ipv4Range.reduce((p, c) => p.add(c.size()), Crunchy.zero()).eq(
            ret.ipv6Range.reduce((p, c) => p.add(c.size()), Crunchy.zero()))) {
            console.log("Range of ipv4 and ipv6 not equal");
            return null;
        }
        ret.ipAssigned = new IpAssigned();
        if (obj.assignedFile) {
            ret.ipAssigned = IpAssigned.fromFile(obj.assignedFile || "./ip_assigned.json");
        }
        return ret;
    }

    public assignGateWay(addrs: IPAddress[]): boolean {
        let ret: IPAddress[] = [];
        for (let ip of addrs) {
            let found = false;
            for (let range of this.ipv4Range.concat(this.ipv6Range)) {
                if (range.start.network().includes(ip)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                console.log("Gateway is not part of Ranges:", addrs);
                return false;
            }
            ret.push(ip);
        }
        this.gateWays.push.apply(this.gateWays, ret);
        return true;
    }

    // private add(ip: IpEntry): IpEntry {
    //     for (let addr of ip.ifAddr.getAddrs()) {
    //         // console.log("add:", addr, this.addrs);
    //         if (this.addrs[addr.to_s()]) {
    //             console.error("duplicated ip")
    //             return null;
    //         }
    //         this.addrs[addr.to_s()] = ip;
    //     }
    //     return ip;
    // }
    // private remove(ip: IpEntry): IpEntry {
    //     for (let addr of ip.ifAddr.getAddrs()) {
    //         if (!this.addrs[addr.to_s()]) {
    //             console.error("unmapped ip")
    //             return null;
    //         }
    //         delete this.addrs[addr.to_s()];
    //     }
    //     return ip;
    // }
    public findIpFromRange(ranges: IpRange[], ifAddrs: IfAddrs.IfAddrs, ipe: IpEntry): IPAddress {
        for (let range of ranges) {
            for (let i = range.start; i.lte(range.target); i = i.inc()) {
                // console.log("findIpFromRange:", i.to_string());
                let found = this.ipAssigned.assign(i, ipe);
                if (found) {
                    return i;
                }
            }
        }
        return null;
    }
    public findFree(connection: WebSocket, ifAddrs: IfAddrs.IfAddrs): IpEntry {
        // fake impl.
        // console.log("findFree-1");
        let ipe = new IpEntry();
        let ipv4 = this.findIpFromRange(this.ipv4Range, ifAddrs, ipe);
        // console.log("findFree-2");
        let ipv6 = this.findIpFromRange(this.ipv6Range, ifAddrs, ipe);
        // console.log("findFree-3");
        if (!ipv4 || !ipv6) {
            // console.log('no free ip found');
            return null;
        }
        // console.log("findFree-4");
        // let free = new IpEntry();
        // console.log("findFree-5");
        ipe.ifAddr = new IfAddrs.IfAddrs()
            .setDests(this.gateWays)
            .addAddr(ipv4)
            .addAddr(ipv6);
        ipe.ws = connection;
        // console.log("findFree-6");
        return ipe;
    }
    public findConnection(bPack: Packet.BinPacket): WebSocket {
        // fake impl
        // console.log("findConnection:", bPack);
        let proto = bPack.data.readUInt8(8)
        if (proto == 0x45) {
            let destIp = Ipv4.from_number(Crunchy.from_8bit([
                bPack.data.readUInt8(24),
                bPack.data.readUInt8(25),
                bPack.data.readUInt8(26),
                bPack.data.readUInt8(27)
            ]), 32);
            let ipe = this.ipAssigned.is_assigned(destIp);
            if (ipe) {
                return ipe.ws;
            }
        } if (proto == 0x60) {
            // 50 41 4b 54 00 00 86 dd 60 02 68 6d 00 40 3a 40 fd 00 00 00 00 00 00 00 00 00 ca fe af fe 00 01 fd 00 00 00 00 00 00 00 00 00 ca fe af fe 10 00 80 00
            let destIp = Ipv6.from_int(Crunchy.from_8bit([
                bPack.data.readUInt8(32), bPack.data.readUInt8(33), bPack.data.readUInt8(34), bPack.data.readUInt8(35),
                bPack.data.readUInt8(36), bPack.data.readUInt8(37), bPack.data.readUInt8(38), bPack.data.readUInt8(39),
                bPack.data.readUInt8(40), bPack.data.readUInt8(41), bPack.data.readUInt8(42), bPack.data.readUInt8(43),
                bPack.data.readUInt8(44), bPack.data.readUInt8(45), bPack.data.readUInt8(46), bPack.data.readUInt8(47)
            ]), 128);
            // console.log("findConnection:6:", destIp.to_string());
            let ipe = this.ipAssigned.is_assigned(destIp);
            if (ipe) {
                return ipe.ws;
            }

        } else {
            console.error("findConnection: unknown packed:", bPack);
        }
        // 50 41 4b 54 00 00 08 00 45 00 00 54 b9 19 40 00 40 01 65 d9 c0 a8 4d 01 c0 a8 4d 64
        // if 
        // for (let addr in this.addrs) {
        //     return this.addrs[addr].ws;
        // }
        // console.log(">>>>findConnection>>>> FAILED");
        return null;
    }
    public release(ipe: IpEntry): IpEntry {
        for (let ip of ipe.ifAddr.getAddrs()) {
            if (!this.ipAssigned.release(ip)) {
                return null;
            }
        }
        return ipe;
    }
}

export default IpStore;
