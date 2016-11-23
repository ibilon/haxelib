package haxelib.client.commands;

import sys.FileSystem;

import haxelib.client.Cli;
import haxelib.client.Command;

class NewRepo implements Command {
	public var name : String = "newrepo";
	public var alias : Array<String> = [];
	public var help : String = "create a new local repository";
	public var category : CommandCategory = Miscellaneous;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var r = doNewRepo();
		if (r.success)
			Cli.print('Local repository created (${r.path})');
		else
			Cli.print('Local repository already exists (${r.path})');
	}

	public static function doNewRepo () : { path:String, success:Bool} {
		var path = #if (haxe_ver >= 3.2) FileSystem.absolutePath(Main.REPODIR) #else Main.REPODIR #end;
		var created = FsUtils.safeDir(path, true);

		return { path: path, success: created };
	}
}
