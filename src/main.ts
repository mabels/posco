
import PoscoServer from './posco_server'
import PoscoClient from './posco_client'
import PoscoContext from './posco_context'
import Config from './config'

console.log("Starting Posco Ecosystem");
let context = new PoscoContext();
context.config = Config.read("posco.json");
 
if (process.argv.find((str)=> str.indexOf("client")!=-1)) {
    PoscoClient.main(context);
} else {
    PoscoServer.main(context);
}
  