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
		var host = haxelib.cli.param("Proxy host");

		if (host == "") {
			if (disableProxy(haxelib)) {
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

		Cli.print("Testing proxy...");
		if (doProxy(haxelib, proxy)) {
			Cli.print("Proxy setup done");
		} else {
			Cli.print("Proxy connection failed");
		}
	}

	public static function disableProxy (haxelib:Main) : Bool {
		var rep = haxelib.getRepository();

		if( FileSystem.exists(rep + "/.proxy") ) {
			FileSystem.deleteFile(rep + "/.proxy");
			return true;
		} else
			return false;
	}

	public static function doProxy (haxelib:Main, proxy) : Bool {
		var rep = haxelib.getRepository();
		Http.PROXY = proxy;

		try Http.requestUrl("http://www.google.com") catch( e : Dynamic ) {
			return false;
		}

		File.saveContent(rep + "/.proxy", haxe.Serializer.run(proxy));
		return true;
	}
}
