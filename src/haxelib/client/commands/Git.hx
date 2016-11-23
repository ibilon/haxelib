package haxelib.client.commands;

import haxelib.client.Command;
import haxelib.client.Vcs;

class Git implements Command {
	public var name : String = "git";
	public var alias : Array<String> = [];
	public var help : String = "use Git repository as library";
	public var category : CommandCategory = Development;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var library = haxelib.cli.param("Library name");
		var url = haxelib.cli.param("Git path");
		var branch = haxelib.cli.paramOpt();
		var subDir = haxelib.cli.paramOpt();
		var version = haxelib.cli.paramOpt();

		doGit(haxelib, library, url, branch, subDir, version);
	}

	public static function doGit (haxelib:Main, library:String, url:String, branch:String, subDir:String, version:String) : Void {
		var rep = haxelib.getRepository();
		Vcs.useVcs(haxelib, VcsID.Git, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, library, url, branch, subDir, version));
	}
}
