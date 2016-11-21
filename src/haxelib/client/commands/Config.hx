package haxelib.client.commands;

import haxelib.client.Cli;
import haxelib.client.Command;

class Config implements Command {
	public var name : String = "config";
	public var alias : Array<String> = [];
	public var help : String = "print the repository path";
	public var category : CommandCategory = Information;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		Cli.print(haxelib.getRepository());
	}
}
