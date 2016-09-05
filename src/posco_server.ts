
import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import * as Packet from './packet';
import Posco from './posco';

import TunatorConnector from './tunator_connector';
import * as IfAddrs from './if_addrs';
 import IPAddress from 'ipaddress';

class PoscoServer extends Posco {
    wss: WebSocket.Server;

    public static start(context: PoscoContext): PoscoServer {
        let ret = new PoscoServer();
        ret.wss = new WebSocket.Server(context.config.server);
        ret.wss.on('connection', (ws) => {
            ws.on('message', (message) => { ret.processMessage(ws, message) });
        });
        return ret;
    }

    public static main(context: PoscoContext) {
        console.log("Starting Server:", context.config.server);
        let tc = TunatorConnector.connect(context.config.server.tunator);
        let ipStore = context.config.server.ipStore;
        ipStore.assignGateWay(context.config.server.tunator.myAddr.addrs);
        let ps = PoscoServer.start(context);
        tc.on('receivePAKT', (ws: WebSocket, bPack: Packet.BinPacket) => {
            let connection = ipStore.findConnection(bPack);
            if (connection) {
                Packet.Packet.sendPakt(connection, bPack);
            } else {
                console.error("unknown pakt");
            }
        });
        ps.on('receivePAKT', (ws: WebSocket, bPack: Packet.BinPacket) => {
            Packet.Packet.sendPakt(tc.client, bPack);
        });
        ps.on('receiveJSON', (ws: WebSocket, jPack: Packet.JsonPacket) => {
            if (jPack.action == "req-connection") {
                let ifAddr = IfAddrs.IfAddrs.fromJson(jPack.data);
                let ipEntry = ipStore.findFree(ws, ifAddr);
                if (ipEntry) {
                    Packet.Packet.sendJson(ws, "res-connection", ipEntry.ifAddr);
                } else {
                    console.error("no address found:");
                }
            } else {
                console.error("unknown message:", jPack.action);
            }
        });
    }

}

export default PoscoServer;