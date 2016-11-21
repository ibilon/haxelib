package haxelib.client.commands;

import haxelib.client.Cli;
import haxelib.client.Command;

class User implements Command {
	public var name : String = "user";
	public var alias : Array<String> = [];
	public var help : String = "list information on a given user";
	public var category : CommandCategory = Information;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var uname = haxelib.cli.param("User name");
		var inf = haxelib.site.user(uname);
		Cli.print("Id: "+inf.name);
		Cli.print("Name: "+inf.fullname);
		Cli.print("Mail: "+inf.email);
		Cli.print("Libraries: ");
		if( inf.projects.length == 0 )
			Cli.print("  (no libraries)");
		for( p in inf.projects )
			Cli.print("  "+p);
	}
}
