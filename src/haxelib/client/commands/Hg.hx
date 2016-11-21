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
		var rep = haxelib.getRepository();
		Vcs.useVcs(haxelib, VcsID.Hg, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, haxelib.cli.param("Library name"), haxelib.cli.param(vcs.name + " path"), haxelib.cli.paramOpt(), haxelib.cli.paramOpt(), haxelib.cli.paramOpt()));
	}
}
