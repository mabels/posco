
import PoscoContext from './posco_context';
import Config from './config';
import TunatorConnector from './tunator_connector';

class Server {
    public static main() {
        let context = new PoscoContext();
        context.config = Config.read("posco.json");
        TunatorConnector.connect(context);
    }
}

Server.main();