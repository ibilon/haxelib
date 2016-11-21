package haxelib.client.commands;

import haxelib.client.Command;

class Set implements Command {
	public var name : String = "set";
	public var alias : Array<String> = [];
	public var help : String = "set the current version for a library";
	public var category : CommandCategory = Basic;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		haxelib.setCurrent(haxelib.getRepository(), haxelib.cli.param("Library"), haxelib.cli.param("Version"), false);
	}
}
