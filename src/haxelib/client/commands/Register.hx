package haxelib.client.commands;

import haxe.crypto.Md5;

import haxelib.client.Cli;
import haxelib.client.Command;

class Register implements Command {
	public var name : String = "register";
	public var alias : Array<String> = [];
	public var help : String = "register a new user";
	public var category : CommandCategory = Development;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var name = haxelib.cli.param("User");
		var email = haxelib.cli.param("Email");
		var fullname = haxelib.cli.param("Fullname");
		var pass = haxelib.cli.param("Password", true);
		var pass2 = haxelib.cli.param("Confirm", true);
		if (pass != pass2) {
			Cli.print("Password does not match");
			Sys.exit(1);
		}

		doRegister(haxelib, name, pass, email, fullname);
		Cli.print("Registration successful");
	}

	public static function doRegister (haxelib:Main, name:String, pass:String, email:String, fullname:String) {
		pass = Md5.encode(pass);
		haxelib.site.register(name, pass, email, fullname);
		return pass;
	}
}
