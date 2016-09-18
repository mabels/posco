import * as IfAddrs from './if_addrs';
import PacketQueue from './packet_queue';

export class TunDevice {
  seq: number;
  ifAddrs: IfAddrs.IfAddrs;
  fromTun: PacketQueue;
  toTun: PacketQueue;
  running: boolean;
  tunFd: number;
  tunDevName: string;

  public static fromJson(obj: any) : TunDevice {
    let ret = new TunDevice();
    ret.seq = obj.seq || 0;
    ret.ifAddrs = IfAddrs.IfAddrs.fromJson(obj.ifAddrs||{});
    ret.fromTun = PacketQueue.fromJson(obj.fromTun||{});
    ret.toTun = PacketQueue.fromJson(obj.toTun||{});
    ret.running = !!obj.running;
    ret.tunFd = ~~obj.tunFd;
    ret.tunDevName = obj.tunDevName;
    return ret;
  }
}

export default TunDevice;