
import {connection} from 'websocket';
import AsJson from './as_json';

class Packet {
    public static sendJson(con: connection, action: string, data: AsJson) {
        con.sendUTF("JSON"+JSON.stringify({
            "action": action,
            "data": data.asJson()
        }));
    }
    public static receive() : string {
       return ""; 
    }
}

export default Packet;