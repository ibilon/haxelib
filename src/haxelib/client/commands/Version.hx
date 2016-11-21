package haxelib.client.commands;

import haxelib.client.Cli;
import haxelib.client.Command;

class Version implements Command {
	public var name : String = "version";
	public var alias : Array<String> = [];
	public var help : String = "print the currently using haxelib version";
	public var category : CommandCategory = Information;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		Cli.print(Main.VERSION);
	}
}
