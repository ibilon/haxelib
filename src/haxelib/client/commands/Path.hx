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
		var libraries = [];
		for (a in haxelib.cli) {
			var a = a.split(":");
			libraries.push({ project: a[0], version: a[1] });
		}

		for (l in doPath(haxelib, libraries)) {
			Cli.print(l);
		}
	}

	public static function doPath (haxelib:Main, libraries:Array<{ project:String, version:String }>) : Array<String> {
		var rep = haxelib.getRepository();

		var list = [];
		for (l in libraries) {
			haxelib.checkRec(rep, l.project, l.version, list);
		}

		var r = [];
		for( d in list ) {
			var s = "";
			var ndir = d.dir + "ndll";
			if (FileSystem.exists(ndir))
				s += '-L $ndir/';

			try {
				var f = File.getContent(d.dir + "extraParams.hxml");
				s += f.trim() + "\n";
			} catch(_:Dynamic) {}

			var dir = d.dir;
			if (d.info.classPath != "") {
				var cp = d.info.classPath;
				dir = haxe.io.Path.addTrailingSlash( d.dir + cp );
			}
			s += dir + "\n";

			s += "-D " + d.project + "=" + d.info.version + "\n";
			r.push(s);
		}
		return r;
	}
}
