package haxelib.client.commands;

import haxelib.client.Command;

class Local implements Command {
	public var name : String = "local";
	public var alias : Array<String> = [];
	public var help : String = "install the specified package locally";
	public var category : CommandCategory = Deprecated("Use `haxelib install <file>` instead");
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		Install.doInstallFile(haxelib, haxelib.getRepository(), haxelib.cli.param("Package"), true, true);
	}
}
