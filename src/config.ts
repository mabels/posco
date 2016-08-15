import * as fs from 'fs';
import * as TunatorConnector from './tunator_connector';
import {IfAddrs} from './if_addrs';
import * as WebSocket from 'ws';

class Tunator {
  public url: string = "ws://localhost:4711/tunator";
  public myAddr: IfAddrs;
  public static fromJson(obj: any) : Tunator {
    let ret = new Tunator();
    ret.url = obj.url || ret.url;
    if (obj.myAddr) {
      ret.myAddr = IfAddrs.fromJson(obj.myAddr);
    }
    return ret;
  }
}

class Server implements WebSocket.IServerOptions {
  public port: number = 8080;
  public static fromJson(obj: any) : Server {
    let ret = new Server();
    ret.port = obj.port || ret.port;
    return ret;
  }
}

class Client {
  public url: string = "ws://localhost:8080/tunator";
  public static fromJson(obj: any) : Client {
    let ret = new Client();
    ret.url = obj.url || ret.url;
    return ret;
  }
}


class Config {
  public tunator: Tunator;
  public server: Server;
  public client: Client;

  public static read(fname: string) : Config {
    let ret = new Config();
    let obj = JSON.parse(fs.readFileSync(fname).toString());
    ret.tunator = Tunator.fromJson(obj.tunator||{});
    ret.server = Server.fromJson(obj.server||{});
    ret.client = Client.fromJson(obj.client||{});
    return ret;
  }
}

export default Config;
