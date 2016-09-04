// import PoscoContext from './posco_context';
import * as IfAddrs from './if_addrs';
import * as WebSocket from 'ws';
import * as Packet from './packet';
import * as fs from 'fs';
import IPAddress from 'ipaddress';

class IpEntry {
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
}

class IpAssigned {
    ipAssigned: { [id: string]: IPAddress } = {};
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

    public is_assigned(ia: IPAddress): IPAddress {
        return this.ipAssigned[ia.to_s()];
    }

    public assign(ia: IPAddress): boolean {
        if (!this.is_assigned(ia)) {
            return false;
        }
        this.ipAssigned[ia.to_s()] = ia;
        return true;
    }

}


class IpStore {
    // context: PoscoContext;
    addrs: { [key: string]: IpEntry } = {};
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
        for (let r of obj) {
            ret.push(IpRange.fromJson([r[0], r[1]]));
        }
        return ret;
    }

    public static fromJson(obj: any): IpStore {
        let ret = new IpStore();
        ret.ipv4Range = IpStore.toIpRangeArray(obj.ipv4Range);
        ret.ipv6Range = IpStore.toIpRangeArray(obj.ipv6Range);
        ret.ipAssigned = IpAssigned.fromFile(obj.assignedFile || "./ip_assigned.json");
        return ret;
    }

    public assignGateWay(addrs: string[]): boolean {
        let ret: IPAddress[] = [];
        for (let ips of addrs) {
            let ip = IPAddress.parse(ips);
            if (!ip) {
                return false;
            }
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

    private add(ip: IpEntry): IpEntry {
        for (let addr of ip.ifAddr.getAddrs()) {
            console.log("add:", addr, this.addrs);
            if (this.addrs[addr]) {
                console.error("duplicated ip")
                return null;
            }
            this.addrs[addr] = ip;
        }
        return ip;
    }
    private remove(ip: IpEntry): IpEntry {
        for (let addr of ip.ifAddr.getAddrs()) {
            if (!this.addrs[addr]) {
                console.error("unmapped ip")
                return null;
            }
            delete this.addrs[addr];
        }
        return ip;
    }
    public findIpFromRange(ranges: IpRange[]): IPAddress {
        for (let range of ranges) {
            for (let i = range.start; i != null; i = i.inc()) {
                let found = this.ipAssigned.assign(i);
                if (found) {
                    return i;
                }
            }
        }
        return null;
    }
    public findFree(connection: WebSocket, ifAddrs: IfAddrs.IfAddrs): IpEntry {
        // fake impl.
        let ipv4 = this.findIpFromRange(this.ipv4Range);
        let ipv6 = this.findIpFromRange(this.ipv6Range);
        if (!ipv4 || !ipv6) {
            console.log('no free ip found');
            return null;
        }
        let free = new IpEntry();
        free.ifAddr = new IfAddrs.IfAddrs()
            .setDests(IPAddress.to_s_vec(this.gateWays))
            .addAddr(ipv4.to_string())
            .addAddr(ipv6.to_string());
        free.ws = connection;
        return this.add(free);
    }
    public findConnection(bPack: Packet.BinPacket): WebSocket {
        // fake impl
        for (let addr in this.addrs) {
            return this.addrs[addr].ws;
        }
        console.log(">>>>findConnection>>>> FAILED");
        return null;
    }
}

export default IpStore;
