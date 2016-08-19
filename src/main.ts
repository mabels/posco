
import PoscoServer from './posco_server'
import PoscoClient from './posco_client'
import PoscoContext from './posco_context'
import Config from './config'

console.log("Starting Posco Ecosystem");
let context = new PoscoContext();
context.config = Config.read("posco.json");

// import * as WebSocket from 'ws';
// function open() {
//   console.log("open");
//     let ret = new WebSocket("ws://127.0.0.1:4719/");
//     ret.on("error", (err) => {
//       console.error("error", err);
//     });
//     ret.on("close", (err) => {
//       console.error("close", err);
//       setTimeout(() => { open() }, 1000);
//     });
// }
//
// open();
// if (false) {
if (process.argv.find((str)=> str.indexOf("client")!=-1)) {
    PoscoClient.main(context);
} else {
    PoscoServer.main(context);
}
// }
