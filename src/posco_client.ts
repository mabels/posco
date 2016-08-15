
import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import Posco from './posco';
import Packet from './packet';



class PoscoClient extends Posco {
    private context: PoscoContext;
    ws: WebSocket;

    constructor(context: PoscoContext) {
        super();
        this.context = context;
    }

    public open() {
      console.log("PoscoClient open:", this.context.config.client.url);
      this.ws = new WebSocket(this.context.config.client.url); 
    }

    public static start(context: PoscoContext) : PoscoClient {
        let pc = new PoscoClient(context);        
        pc.ws = new WebSocket(context.config.client.url); 
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
            pc.processMessage(pc.ws, data);
        });

        pc.ws.on('open', () => {
            console.log('PoscoClient WebSocket Client Connected');
            Packet.sendJson(pc.ws, "req-connection", context.config.tunator.myAddr);
        });
        return pc;
    }

}

export default PoscoClient;