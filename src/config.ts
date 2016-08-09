import * as fs from 'fs';
import * as TunatorConnector from './tunator_connector';

class Tunator {
  public protocol : string = "tunator";
  public url: string = "ws://localhost:4711";
  public static fromJson(obj: any) : Tunator {
    let ret = new Tunator();
    ret.protocol = obj.protocol || ret.protocol;
    ret.url = obj.url || ret.url;
    return ret;
  }
}

class Config {
  public tunator: Tunator;

  public static read(fname: string) : Config {
    let ret = new Config();
    let obj = JSON.parse(fs.readFileSync(fname).toString());
    ret.tunator = Tunator.fromJson(obj);
    return ret;
  }
}

export default Config;