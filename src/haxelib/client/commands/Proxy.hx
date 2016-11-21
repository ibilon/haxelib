package haxelib.client.commands;

import haxe.Http;
import sys.FileSystem;
import sys.io.File;

import haxelib.client.Cli;
import haxelib.client.Command;

class Proxy implements Command {
	public var name : String = "proxy";
	public var alias : Array<String> = [];
	public var help : String = "setup the Http proxy";
	public var category : CommandCategory = Miscellaneous;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var rep = haxelib.getRepository();
		var host = haxelib.cli.param("Proxy host");
		if( host == "" ) {
			if( FileSystem.exists(rep + "/.proxy") ) {
				FileSystem.deleteFile(rep + "/.proxy");
				Cli.print("Proxy disabled");
			} else
				Cli.print("No proxy specified");
			return;
		}
		var port = Std.parseInt(haxelib.cli.param("Proxy port"));
		var authName = haxelib.cli.param("Proxy user login");
		var authPass = authName == "" ? "" : haxelib.cli.param("Proxy user pass");
		var proxy = {
			host : host,
			port : port,
			auth : authName == "" ? null : { user : authName, pass : authPass },
		};
		Http.PROXY = proxy;
		Cli.print("Testing proxy...");
		try Http.requestUrl("http://www.google.com") catch( e : Dynamic ) {
			Cli.print("Proxy connection failed");
			return;
		}
		File.saveContent(rep + "/.proxy", haxe.Serializer.run(proxy));
		Cli.print("Proxy setup done");
	}
}
