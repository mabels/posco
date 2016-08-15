import PoscoContext from './posco_context';
import * as IfAddrs from './if_addrs';
import * as WebSocket from 'ws';
import * as Packet from './packet';

class IpStore {
    context: PoscoContext;
    constructor(context: PoscoContext) {
        this.context = context;
    }
    public findFree(connection: WebSocket, ifAddrs: IfAddrs.IfAddrs) : IfAddrs.IfAddrs {
       return null;
    }
    public findConnection(bPack: Packet.BinPacket) : WebSocket {
        return null;
    }
}

export default IpStore;