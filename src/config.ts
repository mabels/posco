import * as fs from 'fs';
import * as TunatorConnector from './tunator_connector';
import {IfAddrs} from './if_addrs';
import * as WebSocket from 'ws';
import IpStore from './ip_store';

export class Tunator {
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

export class Server implements WebSocket.IServerOptions {
  public port: number = 8080;
  public tunator: Tunator;
  public ipStore: IpStore;
  public static fromJson(obj: any) : Server {
    let ret = new Server();
    ret.port = obj.port || ret.port;
    ret.tunator = Tunator.fromJson(obj.tunator||{});
    ret.ipStore = IpStore.fromJson(obj.ipStore||{});
    return ret;
  }
}

export class Client {
  public url: string = "ws://localhost:8080/posco";
  public tunator: Tunator;
  public static fromJson(obj: any) : Client {
    let ret = new Client();
    ret.url = obj.url || ret.url;
    ret.tunator = Tunator.fromJson(obj.tunator||{});
    return ret;
  }
}


export class Config {
  public server: Server;
  public client: Client;

  public static read(fname: string) : Config {
    let ret = new Config();
    let obj = JSON.parse(fs.readFileSync(fname).toString());
    ret.server = Server.fromJson(obj.server||{});
    ret.client = Client.fromJson(obj.client||{});
    return ret;
  }
}

export default Config;
