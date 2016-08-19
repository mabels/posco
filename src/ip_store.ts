import PoscoContext from './posco_context';
import * as IfAddrs from './if_addrs';
import * as WebSocket from 'ws';
import * as Packet from './packet';

class IpEntry {
    public ifAddr: IfAddrs.IfAddrs;
    public ws: WebSocket;
}
class IpStore {
    context: PoscoContext;
    addrs: { [key: string]: IpEntry } = {};

    constructor(context: PoscoContext) {
        this.context = context;
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
    public findFree(connection: WebSocket, ifAddrs: IfAddrs.IfAddrs): IpEntry {
        // fake impl.
        let free = new IpEntry();
        free.ifAddr = new IfAddrs.IfAddrs().setDest("192.168.77.1")
            .addAddr("192.168.77.100/24").addAddr("fd00::cafe:affe:100/112");
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