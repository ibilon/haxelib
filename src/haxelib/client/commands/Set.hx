package haxelib.client.commands;

import haxelib.client.Command;

class Set implements Command {
	public var name : String = "set";
	public var alias : Array<String> = [];
	public var help : String = "set the current version for a library";
	public var category : CommandCategory = Basic;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var library = haxelib.cli.param("Library");
		var version = haxelib.cli.param("Version");
		doSet(haxelib, library, version);
	}

	public static function doSet (haxelib:Main, library:String, version:String) {
		haxelib.setCurrent(haxelib.getRepository(), library, version, false);
	}
}
