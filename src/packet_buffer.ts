

export class PacketBuffer {
  size: number;
  mtu: number;
  packetSize: number;
  public static fromJson(obj: any) : PacketBuffer {
    let ret = new PacketBuffer();
    ret.size = ~~obj['size'];
    ret.mtu = ~~obj['mtu'];
    ret.packetSize = ~~obj['packetSize'];
    return ret;
  }
}

export default PacketBuffer;