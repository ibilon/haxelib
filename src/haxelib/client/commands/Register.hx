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
		doRegister(haxelib, haxelib.cli.param("User"));
		Cli.print("Registration successful");
	}

	public static function doRegister (haxelib:Main, name:String) {
		var param = haxelib.cli.param;

		var email = param("Email");
		var fullname = param("Fullname");
		var pass = param("Password", true);
		var pass2 = param("Confirm", true);
		if (pass != pass2)
			throw "Password does not match";
		pass = Md5.encode(pass);
		haxelib.site.register(name,pass,email,fullname);
		return pass;
	}
}
