package haxelib.client.commands;

import sys.FileSystem;
import sys.io.File;

import haxelib.client.Cli;
import haxelib.client.Command;

using StringTools;

class Path implements Command {
	public var name : String = "path";
	public var alias : Array<String> = [];
	public var help : String = "give paths to libraries";
	public var category : CommandCategory = Information;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var rep = haxelib.getRepository();
		var list = [];
		for (a in haxelib.cli) {
			var a = a.split(":");
			haxelib.checkRec(rep, a[0], a[1], list);
		}
		for( d in list ) {
			var ndir = d.dir + "ndll";
			if (FileSystem.exists(ndir))
				Sys.print('-L $ndir/');

			try {
				var f = File.getContent(d.dir + "extraParams.hxml");
				Cli.print(f.trim());
			} catch(_:Dynamic) {}

			var dir = d.dir;
			if (d.info.classPath != "") {
				var cp = d.info.classPath;
				dir = haxe.io.Path.addTrailingSlash( d.dir + cp );
			}
			Cli.print(dir);

			Cli.print("-D " + d.project + "="+d.info.version);
		}
	}
}
