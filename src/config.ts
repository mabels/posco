import * as fs from 'fs';
import * as TunatorConnector from './tunator_connector';
import {IfAddrs} from './if_addrs';
import * as WebSocket from 'ws';
import IpStore from './ip_store';
import * as Url  from 'url';
import * as Http  from 'http';
import * as Https  from 'https';

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

export class HttpsOptions {
  public static fromJson(obj: any) : Https.ServerOptions {
    if (!obj) {
      return null;
    }
    return {
        key: fs.readFileSync(obj.key).toString() || "",
        cert: fs.readFileSync(obj.cert).toString() || ""
      }
  }
}

export class Bind {
  public url : Url.Url;
  public httpsOptions: Https.ServerOptions;
  public static fromJson(obj: any) : Bind {
    let ret = new Bind();
    ret.url = Url.parse(obj.url||"ws://0.0.0.0:4711");
    ret.httpsOptions = HttpsOptions.fromJson(obj.httpsOptions);
    return ret;
  }
}

// implements WebSocket.IServerOptions
export class Server {
  public port: number = 8080;
  public tunator: Tunator;
  public ipStore: IpStore;
  public binds: Bind[] = [];
  public static fromJson(obj: any) : Server {
    let ret = new Server();
    ret.port = obj.port || ret.port;
    ret.tunator = Tunator.fromJson(obj.tunator||{});
    ret.ipStore = IpStore.fromJson(obj.ipStore||{});
    for (let bind of (obj.binds||[{url: "ws://0.0.0.0:4711"}])) {
      // console.log(">>>>", bind);
      ret.binds.push(Bind.fromJson(bind));
    }
    return ret;
  }
}

export class Client {
  public url: Url.Url;
  public httpsOptions: Https.ServerOptions;
  public tunator: Tunator;
  public static fromJson(obj: any) : Client {
    let ret = new Client();
    ret.url = Url.parse(obj.url||"ws://localhost:4711");
    ret.tunator = Tunator.fromJson(obj.tunator||{});
    ret.httpsOptions = HttpsOptions.fromJson(obj.httpsOptions);
    return ret;
  }
}


export class Config {
  public server: Server;
  public client: Client;

 public static readFromString(str: string) : Config {
    let ret = new Config();
    let obj = JSON.parse(str);
    ret.server = Server.fromJson(obj.server||{});
    ret.client = Client.fromJson(obj.client||{});
    return ret;
  }
}

export default Config;
