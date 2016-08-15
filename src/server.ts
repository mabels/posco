
import PoscoContext from './posco_context';
import Config from './config';
import TunatorConnector from './tunator_connector';
import PoscoServer from './posco_server';
import * as Packet from './packet';
import * as IfAddrs from './if_addrs';
import * as WebSocket from 'ws';
import IpStore from './ip_store';

class Server {
    public static main() {
        let context = new PoscoContext();
        context.config = Config.read("posco.json");
        let tc = TunatorConnector.connect(context);
        if (process.argv.find((str)=> str.indexOf("client")!=-1)) {
        } else {
            let ipStore = new IpStore(context);
            let ps = PoscoServer.start(context);
            tc.on('receivePakt', (bPack: Packet.BinPacket) => {
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
                    Packet.Packet.sendJson(ws, "res-connection", ipStore.findFree(ws, ifAddr));
                } else {
                    console.error("unknown message:", jPack.action);
                }
            });
        }
    }
}

Server.main();