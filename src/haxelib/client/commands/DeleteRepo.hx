package haxelib.client.commands;

import sys.FileSystem;

import haxelib.client.Cli;
import haxelib.client.Command;

class DeleteRepo implements Command {
	public var name : String = "deleterepo";
	public var alias : Array<String> = [];
	public var help : String = "delete the local repository";
	public var category : CommandCategory = Miscellaneous;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var r = doDeleteRepo();
		if (r.success)
			Cli.print('Local repository deleted (${r.path})');
		else
			Cli.print('No local repository found (${r.path})');
	}

	public static function doDeleteRepo () : { path:String, success:Bool} {
		var path = #if (haxe_ver >= 3.2) FileSystem.absolutePath(Main.REPODIR) #else Main.REPODIR #end;
		var deleted = FsUtils.deleteRec(path);

		return { path: path, success: deleted };
	}
}
