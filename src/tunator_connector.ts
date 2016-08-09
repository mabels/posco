


import {client as WebSocketClient, connection} from 'websocket';
import PoscoContext from './posco_context';

class TunatorConnector {
    private client: WebSocketClient = new WebSocketClient();
    private context: PoscoContext;

    private open() {
      console.log("TunatorConnector open:", this.context.config.tunator.url);
      this.client.connect(this.context.config.tunator.url, 
                          this.context.config.tunator.protocol);
    }
  
    public constructor(context: PoscoContext) {
        this.context = context;
    }
    public static connect(context: PoscoContext)  {
        if (context.tunatorConnector) {
            console.error("TunatorConnector can't have multiple connections");
            return;
        }
        let tc = new TunatorConnector(context);

        tc.client.on('connectFailed', (error) => {
            console.error('TunatorConnector Error: ' + error.toString() + " reconnect");
            setTimeout(() => { tc.open() }, 1000);
        });

        tc.client.on('connect', (connection: connection) => {
            console.log('TunatorConnector WebSocket Client Connected');
            connection.on('error', (error) => {
                console.log("TunatorConnector Connection Error: " + error.toString() + " reconnect");
                setTimeout(() => { tc.open() }, 1000);
            });
            connection.on('close', () => {
                console.log("TunatorConnector Connection Closed: reconnect");
                setTimeout(() => { tc.open() }, 1000);
            });
            connection.on('message', (message) => {
                if (message.type === 'utf8') {
                    console.log("Received: '" + message.utf8Data + "'");
                }
            });
        });
        tc.open();
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
