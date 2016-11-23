package haxelib.client.commands;

import haxelib.client.Command;
import haxelib.client.Vcs;

class Hg implements Command {
	public var name : String = "hg";
	public var alias : Array<String> = [];
	public var help : String = "use Mercurial (hg) repository as library";
	public var category : CommandCategory = Development;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var library = haxelib.cli.param("Library name");
		var url = haxelib.cli.param("Mercurial path");
		var branch = haxelib.cli.paramOpt();
		var subDir = haxelib.cli.paramOpt();
		var version = haxelib.cli.paramOpt();

		doHg(haxelib, library, url, branch, subDir, version);
	}

	public static function doHg (haxelib:Main, library:String, url:String, branch:String, subDir:String, version:String) : Void {
		var rep = haxelib.getRepository();
		Vcs.useVcs(haxelib, VcsID.Hg, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, library, url, branch, subDir, version));
	}
}
