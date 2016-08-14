import * as fs from 'fs';
import * as TunatorConnector from './tunator_connector';
import {IfAddrs} from './if_addrs';

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

class Config {
  public tunator: Tunator;

  public static read(fname: string) : Config {
    let ret = new Config();
    let obj = JSON.parse(fs.readFileSync(fname).toString());
    ret.tunator = Tunator.fromJson(obj.tunator||{});
    return ret;
  }
}

export default Config;
