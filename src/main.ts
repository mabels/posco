
import PoscoServer from './posco_server'
import PoscoClient from './posco_client'
import PoscoContext from './posco_context'
import Config from './config'
import * as Fs from 'fs'

console.log("Starting Posco Ecosystem");
let context = new PoscoContext();
let lastArg = process.argv[process.argv.length-1];
let fs : Buffer = null
if (lastArg.substr(-".json".length) == ".json") {
    fs = Fs.readFileSync(lastArg);
}
if (!fs) {
    fs = Fs.readFileSync("posco.json");
}
context.config = Config.readFromString(fs.toString());
if (process.argv.find((str)=> str.indexOf("client")!=-1)) {
    PoscoClient.main(context);
} else {
    PoscoServer.main(context);
}
// }
