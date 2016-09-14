


import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import Packet from './packet';

import * as events from 'events';
import * as Config from './config';
import Posco from './posco';

interface CbPacket { (pack: Packet): void }

class TunatorConnector extends Posco {
    public client: WebSocket;
    private config: Config.Tunator;
    // private eventRecvPackets: CbPacket[] = [];

    public open() {
      console.log("TunatorConnector {open:", this.config.url);
      this.client = new WebSocket(this.config.url);
      this.client.on('error', (error) => {
          console.error("TunatorConnector Connection Error: " + error.toString() + " reconnect");
          //            setTimeout(() => { tc.open() }, 1000);
      });
      this.client.on('close', () => {
          console.log("TunatorConnector Connection Closed: reconnect");
          setTimeout(() => { this.open() }, 1000);
      });
      this.client.on('message', (data, flags) => {
          //let pacType = Packet.receive(data);
        //   console.log(">>>TC:", flags, Buffer.from(data).toString());
          this.processMessage(null, Buffer.from(data));
      });
      this.client.on('open', () => {
          console.log('TunatorConnector WebSocket Client Connected', this.config.myAddr.asJson());
          Packet.sendJson(this.client, "init", this.config.myAddr);
      });
      console.log("TunatorConnector }open:", this.config.url);
    }

    public constructor(config: Config.Tunator) {
        super();
        this.config = config;
    }

    // public on(event: string, cb: CbPacket): this {
    //    if (event == "receivePacket") {
    //        this.eventRecvPackets.push(cb);
    //    }
    //    return this;
    // }
    public static connect(config: Config.Tunator) : TunatorConnector {
        let tc = new TunatorConnector(config);
        tc.open();
        return tc;
    }
}

export default TunatorConnector;

// module.exports = function(config) {


// client.onerror = function() {
//     console.log('Connection Error');
// };

// client.onopen = function() {
//     console.log('WebSocket Client Connected');

//     function sendNumber() {
//         if (client.readyState === client.OPEN) {
//             var number = Math.round(Math.random() * 0xFFFFFF);
//             client.send(number.toString());
//             setTimeout(sendNumber, 1000);
//         }
//     }
//     sendNumber();
// };

// client.onclose = function() {
//     console.log('echo-protocol Client Closed');
// };

// client.onmessage = function(e) {
//     if (typeof e.data === 'string') {
//         console.log("Received: '" + e.data + "'");
//     }
// };
