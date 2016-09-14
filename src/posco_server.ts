
import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import * as Packet from './packet';
import Posco from './posco';
import * as Http from 'http';
import * as Https from 'https';
import * as Url  from 'url';

import TunatorConnector from './tunator_connector';
import * as IfAddrs from './if_addrs';
 import IPAddress from 'ipaddress';

class PoscoServer extends Posco {
    wss: WebSocket.Server;

    public static start(context: PoscoContext): PoscoServer {
        let ret = new PoscoServer();
        //console.log("BindUrl:", context.config.server.bindUrl);
        let url = context.config.server.bindUrl;
        //console.log(url);
        //let httpserver : Http.Server | Https.Server; 
        console.log("Bind to:", url.href);
        if (url.protocol == "wss:") { 
        //console.log(">>>>>>>>>>>>>",context.config.server.httpsOptions);
          let httpserver = Https.createServer(context.config.server.httpsOptions);
          httpserver.listen(+url.port, url.hostname);
          ret.wss = new WebSocket.Server({ server: httpserver});
        } else {
          let httpserver = Http.createServer();
          httpserver.listen(+url.port, url.hostname);
          ret.wss = new WebSocket.Server({ server: httpserver});
        }
        ret.wss.on('connection', (ws) => {
            ws.on('message', (message) => { ret.processMessage(ws, message) });
        });
        return ret;
    }

    public static main(context: PoscoContext) {
    //console.log("Starting Server:", context.config.server);
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
