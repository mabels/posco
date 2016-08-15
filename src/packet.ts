
import * as WebSocket from 'ws';
import AsJson from './as_json';

export interface PackData {
    type: string
    data: any;
}
class PackType {
    public type: string;
    constructor(type:string) {
        this.type = type;
    }
}

export class JsonPacket extends PackType implements PackData {
    public data: any;
    public action: string;
    constructor(type:string, buf: Buffer) {
        super(type);
        let obj = JSON.parse(buf.slice(4).toString("utf8"));
        this.action = obj.action || "unknown-action";
        this.data = obj.data || {};
    }
}
export class BinPacket extends PackType implements PackData {
    // HOLDS the PAKT Prefix!!!!
    public data: Buffer;
    constructor(type: string, buf: Buffer) {
        super(type);
        this.data = buf;
    }
}

export class Packet {
    public static sendJson(con: WebSocket, action: string, data: AsJson) {
        con.send("JSON"+JSON.stringify({
            "action": action,
            "data": data.asJson()
        }));
    }
    public static sendPakt(con: WebSocket, bPack: BinPacket) {
        try {
            console.log("bPack:", bPack.data.length, Buffer.from(bPack.data));
            con.send(bPack.data, { binary: true, mask: true }); //including PAKT 
        } catch (e) {
            console.error("sendPakt:", e, con);
        }
    }
    public static receive(buf: Buffer) : PackData {
        let type = buf.slice(0, 4).toString('utf8');
        //console.log(buf.length, "receive:", type);
        if (type == "JSON") {
           return new JsonPacket(type, buf); 
        } else if (type == "PAKT") {
           return new BinPacket(type, buf); 
        } 
        return null;
    }
}

export default Packet;