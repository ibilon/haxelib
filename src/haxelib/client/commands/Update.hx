package haxelib.client.commands;

import sys.FileSystem;

import haxelib.client.Cli;
import haxelib.client.Command;
import haxelib.client.Vcs;

class Update implements Command {
	public var name : String = "update";
	public var alias : Array<String> = ["upgrade"];
	public var help : String = "update a single library (if given) or all installed libraries";
	public var category : CommandCategory = Basic;
	public var net : Bool = true;

	public function run (h:Main) : Void {
		var rep = h.getRepository();

		var prj = h.cli.paramOpt();
		if (prj != null) {
			prj = h.projectNameToDir(rep, prj); // get project name in proper case
			if (!updateByName(h, rep, prj))
				Cli.print(prj + " is up to date");
			return;
		}

		var state = { rep : rep, prompt : true, updated : false };
		for( p in FileSystem.readDirectory(state.rep) ) {
			if( p.charAt(0) == "." || !FileSystem.isDirectory(state.rep+"/"+p) )
				continue;
			var p = Data.unsafe(p);
			Cli.print("Checking " + p);
			try {
				doUpdate(h, p, state);
			} catch (e:VcsError) {
				if (!e.match(VcsUnavailable(_)))
					neko.Lib.rethrow(e);
			}
		}
		if( state.updated )
			Cli.print("Done");
		else
			Cli.print("All libraries are up-to-date");
	}

	public static function updateByName(haxelib:Main, rep:String, prj:String) {
		var state = { rep : rep, prompt : false, updated : false };
		doUpdate(haxelib, prj,state);
		return state.updated;
	}

	public static function doUpdate (h:Main, p : String, state : { updated : Bool, rep : String, prompt : Bool } ) {
		var pdir = state.rep + Data.safe(p);

		var vcs = Vcs.getVcsForDevLib(pdir, h.settings);
		if(vcs != null) {
			if(!vcs.available)
				throw VcsError.VcsUnavailable(vcs);

			var oldCwd = Sys.getCwd();
			Sys.setCwd(pdir + "/" + vcs.directory);
			var success = vcs.update(p);

			state.updated = success;
			Sys.setCwd(oldCwd);
		} else {
			var latest = try h.site.getLatestVersion(p) catch( e : Dynamic ) { Cli.print(e); return; };

			if( !FileSystem.exists(pdir+"/"+Data.safe(latest)) ) {
				if( state.prompt ) {
					if (!Cli.ask("Update "+p+" to "+latest))
						return;
				}
				haxelib.client.commands.Install.doInstall(h, state.rep, p, latest,true);
				state.updated = true;
			} else
				h.setCurrent(state.rep, p, latest, true);
		}
	}
}
