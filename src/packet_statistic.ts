

export class PacketStatisticData {
  allocFailed: number;
  allocOk: number;
  pushActionFailed: number;
  popActionFailed: number;
  pushTimeout: number;
  popTimeout: number;
  pushPacketSize: number;
  popPacketSize: number;
  pushOk: number;
  popOk: number;
  popEmpty: number;
  pushFailed: number;
  public static fromJson(obj: any): PacketStatisticData {
    let ret = new PacketStatisticData();
    ret.allocFailed = ~~obj.allocFailed;
    ret.allocOk = ~~obj.allocOk;
    ret.pushActionFailed = ~~obj.pushActionFailed;
    ret.popActionFailed = ~~obj.popActionFailed;
    ret.pushTimeout = ~~obj.pushTimeout;
    ret.popTimeout = ~~obj.popTimeout;
    ret.pushPacketSize = ~~obj.pushPacketSize;
    ret.popPacketSize = ~~obj.popPacketSize;
    ret.pushOk = ~~obj.pushOk;
    ret.popOk = ~~obj.popOk;
    ret.popEmpty = ~~obj.popEmpty;
    ret.pushFailed = ~~obj.pushFailed;
    return ret;
  }
}
export class PacketStatistic {
  started: Date;
  current: PacketStatisticData;
  total: PacketStatisticData;

  public static fromJson(obj: any): PacketStatistic {
    let ret = new PacketStatistic();
    ret.started = new Date(obj.started);
    ret.current = PacketStatisticData.fromJson(obj.current);
    ret.total = PacketStatisticData.fromJson(obj.total);
    return ret;
  }
}

export default PacketStatistic;