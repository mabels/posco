
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
    wsss: WebSocket.Server[] = [];

    public static start(context: PoscoContext): PoscoServer {
        let ret = new PoscoServer();
        //console.log("BindUrl:", context.config.server.bindUrl);
        for (let bind of context.config.server.binds) {
          console.log("Bind to:", bind.url.href);
          let httpserver : Http.Server | Https.Server;
          if (bind.url.protocol == "wss:") {
          //console.log(">>>>>>>>>>>>>",context.config.server.httpsOptions);
            bind.httpsOptions.requestCert = true;
            bind.httpsOptions.rejectUnauthorized = false;
            httpserver = Https.createServer(bind.httpsOptions);
          } else {
            httpserver = Http.createServer();
          }
          httpserver.listen(+bind.url.port, bind.url.hostname);
          httpserver.on("request", (request: any, response: any) => { 
            if (request.client.authorized) {
                response.end('Welcome to Posco:' + request.url);
            } else {
                response.end('You are unknown to Posco:' + request.url);
            }
          });
          let wss = new WebSocket.Server({ server: httpserver});
          wss.on('connection', (ws) => {
              console.log((<any>(ws))._socket.getCipher());
              console.log((<any>(ws))._socket.getPeerCertificate());
              console.log((<any>(ws))._socket.authorized, (<any>(ws))._socket.authorizationError);
              ws.on('message', (message) => { ret.processMessage(ws, message) });
          });
          ret.wsss.push(wss);
        }
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
        tc.on("receiveJSON", (ws: WebSocket, jPack: Packet.JsonPacket) => {
            console.log("jPack", jPack);
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
