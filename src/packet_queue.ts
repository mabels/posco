
import PacketBuffer from './packet_buffer'
import PacketStatistic from './packet_statistic'

export class PacketQueue {
  pb: PacketBuffer;
  ps: PacketStatistic;
  public static fromJson(obj: any) : PacketQueue {
    let ret = new PacketQueue();
    ret.pb = PacketBuffer.fromJson(obj['pb']||{});
    ret.ps = PacketStatistic.fromJson(obj['ps']||{});
    return ret;
  }
}

export default PacketQueue;