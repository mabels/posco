


import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import Packet from './packet';

import * as events from 'events';

interface CbPacket { (pack: Packet): void }

class TunatorConnector extends events.EventEmitter {
    public client: WebSocket;
    private context: PoscoContext;
    private eventRecvPackets: CbPacket[];

    public open() {
      console.log("TunatorConnector open:", this.context.config.tunator.url);
      this.client = new WebSocket(this.context.config.tunator.url); 
    }
  
    public constructor(context: PoscoContext) {
        super();
        this.context = context;
    }

    public on(event: string, cb: CbPacket): this {
       if (event == "recvPacket") {
           this.eventRecvPackets.push(cb);
       }
       return this; 
    }
    public static connect(context: PoscoContext)  {
        if (context.tunatorConnector) {
            console.error("TunatorConnector can't have multiple connections");
            return;
        }
        let tc = new TunatorConnector(context);
        tc.open();
        tc.client.on('error', (error) => {
            console.log("TunatorConnector Connection Error: " + error.toString() + " reconnect");
            setTimeout(() => { tc.open() }, 1000);
        });
        tc.client.on('close', () => {
            console.log("TunatorConnector Connection Closed: reconnect");
            setTimeout(() => { tc.open() }, 1000);
        });
        tc.client.on('message', (data, flags) => {
            let pacType = Packet.receive(data);
            //console.log(">>>", pacType);
            tc.eventRecvPackets.forEach((cb) => cb(pacType));
        });

        tc.client.on('open', () => {
            console.log('TunatorConnector WebSocket Client Connected');
            Packet.sendJson(tc.client, "init", context.config.tunator.myAddr);
        });
        //tc.open();
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
