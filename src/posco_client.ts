import * as Https from 'https';
import * as Tls from 'tls';

import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import Posco from './posco';
import * as Packet from './packet';
import * as IfAddrs from './if_addrs';
import IPAddress from 'ipaddress';
import * as Config from './config';
import TunatorConnector from './tunator_connector';


class PoscoClient extends Posco {
    private config: Config.Client;
    private tunatorConnector: TunatorConnector;
    ws: WebSocket;

    constructor(config: Config.Client) {
        super();
        this.config = config;
    }

    public open() {
      console.log("PoscoClient open:", this.config.url.href, 
        !!(this.config.httpsOptions && this.config.httpsOptions.key && this.config.httpsOptions.cert));
      this.ws = new WebSocket(this.config.url.href, this.config.httpsOptions||{});
    }

    public static main(context: PoscoContext) : PoscoClient {
        console.log("Starting PoscoClient");
        let pc = new PoscoClient(context.config.client);
        pc.on('receivePAKT', (ws: WebSocket, bPack: Packet.BinPacket) => {
            //console.log("ws.receivePacket:", bPack);
            Packet.Packet.sendPakt(pc.tunatorConnector.client, bPack);
        });
        pc.on('receiveJSON', (ws: WebSocket, jPack: Packet.JsonPacket) => {
            if (jPack.action == "res-connection") {
                console.log((<any>(ws))._socket.getCipher());
                console.log((<any>(ws))._socket.getPeerCertificate());

                let ifAddr = IfAddrs.IfAddrs.fromJson(jPack.data);
                context.config.client.tunator.myAddr = ifAddr;
                if (pc.tunatorConnector) {
                    console.error("duplicated: es-connection");
                    return;
                }
                ifAddr.remoteAddress = IPAddress.parse((<any>ws)._socket.remoteAddress);
                pc.tunatorConnector = TunatorConnector.connect(context.config.client.tunator);
                pc.tunatorConnector.on("receivePAKT", (xx: WebSocket, packet: Packet.PackData) => {
                    //console.log("ws.sendPacket:", packet);
                    Packet.Packet.sendPakt(ws, packet);
                })
                console.log("res-connection", context.config.client.tunator);
            } else {
                console.error("unknown message:", jPack.action);
            }
        });

        pc.open();
        pc.ws.on('error', (error) => {
            pc.ws = null;
            console.log("PoscoClient Connection Error: " + error.toString() + " reconnect");
            setTimeout(() => { pc.open() }, 1000);
        });
        pc.ws.on('close', () => {
            pc.ws = null;
            console.log("PoscoClient Connection Closed: reconnect");
            setTimeout(() => { pc.open() }, 1000);
        });
        pc.ws.on('message', (data, flags) => {
            //console.log(">>>", flags);
            pc.processMessage(pc.ws, data);
        });
        pc.ws.on('open', () => {
            console.log('PoscoClient WebSocket Client Connected');
            Packet.Packet.sendJson(pc.ws, "req-connection", pc.config.tunator.myAddr||(new IfAddrs.IfAddrs()));
        });
        return pc;
    }

}

export default PoscoClient;
