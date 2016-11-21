package haxelib.client.commands;

import haxelib.client.Command;

class SelfUpdate implements Command {
	public var name : String = "selfupdate";
	public var alias : Array<String> = [];
	public var help : String = "update haxelib itself";
	public var category : CommandCategory = Deprecated('Use `haxelib --global update ${haxelib.client.Main.HAXELIB_LIBNAME}` instead');
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		Update.updateByName(haxelib, haxelib.getGlobalRepository(), Main.HAXELIB_LIBNAME);
	}
}
