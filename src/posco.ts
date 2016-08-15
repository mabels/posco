
import * as Packet from './packet';
import * as WebSocket from 'ws';


interface CbPacket { (ws: WebSocket, pack: Packet.Packet): void }

class Posco {
   cbReceiveJson: CbPacket[];
   cbReceivePakt: CbPacket[];

    public on(event: string, cb: CbPacket) : Posco {
        if (event == "receivePAKT") {
           this.cbReceivePakt.push(cb); 
        }
        if (event == "receiveJSON") {
           this.cbReceiveJson.push(cb); 
        }
        return this;
    }

    public processMessage(ws: WebSocket, message: any) {
        let pacType = Packet.Packet.receive(message);
        if (pacType.type == "JSON") {
            this.cbReceiveJson.forEach(cb => cb(ws, pacType)); 
        } else if (pacType.type == "PAKT") {
            this.cbReceivePakt.forEach(cb => cb(ws, pacType)); 
        }
    }

}

export default Posco;
 