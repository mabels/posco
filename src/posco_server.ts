
import * as WebSocket from 'ws';
import PoscoContext from './posco_context';
import * as Packet from './packet';
import Posco from './posco';


class PoscoServer extends Posco {
    wss: WebSocket.Server;
 
    public static start(context: PoscoContext) : PoscoServer {
        let ret = new PoscoServer();        
        ret.wss = new WebSocket.Server(context.config.server);
        ret.wss.on('connection', (ws) => {
            ws.on('message', (message) => { ret.processMessage(ws, message) });
        });
        return ret;
    }

}

export default PoscoServer;