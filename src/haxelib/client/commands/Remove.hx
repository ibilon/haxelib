package haxelib.client.commands;

import sys.FileSystem;
import sys.io.File;

import haxelib.client.Cli;
import haxelib.client.Command;
import haxelib.client.FsUtils;

using StringTools;

class Remove implements Command {
	public var name : String = "remove";
	public var alias : Array<String> = [];
	public var help : String = "remove a given library/version";
	public var category : CommandCategory = Basic;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var rep = haxelib.getRepository();
		var prj = haxelib.cli.param("Library");
		var version = haxelib.cli.paramOpt();
		var pdir = rep + Data.safe(prj);
		if( version == null ) {
			if( !FileSystem.exists(pdir) )
				throw "Library "+prj+" is not installed";

			if (prj == Main.HAXELIB_LIBNAME && haxelib.isHaxelibRun) {
				Cli.print('Error: Removing "${Main.HAXELIB_LIBNAME}" requires the --system flag');
				Sys.exit(1);
			}

			FsUtils.deleteRec(pdir);
			Cli.print("Library "+prj+" removed");
			return;
		}

		var vdir = pdir + "/" + Data.safe(version);
		if( !FileSystem.exists(vdir) )
			throw "Library "+prj+" does not have version "+version+" installed";

		var cur = File.getContent(pdir + "/.current").trim(); // set version regardless of dev
		if( cur == version )
			throw "Can't remove current version of library "+prj;
		var dev = try haxelib.getDev(pdir) catch (_:Dynamic) null; // dev is checked here
		if( dev == vdir )
			throw "Can't remove dev version of library "+prj;
		FsUtils.deleteRec(vdir);
		Cli.print("Library "+prj+" version "+version+" removed");
	}
}
