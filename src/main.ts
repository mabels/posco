
import PoscoServer from './posco_server'
import PoscoClient from './posco_client'
import PoscoContext from './posco_context'
import Config from './config'
import * as Fs from 'fs'
import * as Path from 'path'

console.log("Starting Posco Ecosystem");
let context = new PoscoContext();
let lastArg = process.argv[process.argv.length-1];
let fname : string = "posco.json";
if (lastArg.substr(-".json".length) == ".json") {
    fname = lastArg;
}
let fs = Fs.readFileSync(fname);
context.config = Config.readFromString(fs.toString(), Path.dirname(fname));
if (process.argv.find((str)=> str.indexOf("client")!=-1)) {
    PoscoClient.main(context);
} else {
    PoscoServer.main(context);
}
// }
