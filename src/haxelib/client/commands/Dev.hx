package haxelib.client.commands;

import sys.FileSystem;
import sys.io.File;

import haxelib.client.Cli;
import haxelib.client.Command;

using StringTools;

class Dev implements Command {
	public var name : String = "dev";
	public var alias : Array<String> = [];
	public var help : String = "set the development directory for a given library";
	public var category : CommandCategory = Development;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var project = haxelib.cli.param("Library");
		var dir = haxelib.cli.paramOpt();

		try {
			doDev(haxelib, project, dir);
		} catch (e:String) {
			Cli.print(e);
			Sys.exit(1);
		}

		if (dir != null) {
			Cli.print('Development directory set to $dir');
		} else {
			Cli.print("Development directory disabled");
		}
	}

	public static function doDev (haxelib:Main, project:String, dir:String) {
		var rep = haxelib.getRepository();
		var proj = rep + Data.safe(project);
		var devfile = proj+"/.dev";

		if (!FileSystem.exists(proj)) {
			FileSystem.createDirectory(proj);
		}

		if (dir == null) {
			if (FileSystem.exists(devfile))
				FileSystem.deleteFile(devfile);
		}
		else {
			while ( dir.endsWith("/") || dir.endsWith("\\") ) {
				dir = dir.substr(0,-1);
			}
			if (!FileSystem.exists(dir)) {
				throw 'Directory $dir does not exist';
			} else {
				dir = FileSystem.fullPath(dir);
				try {
					File.saveContent(devfile, dir);
				}
				catch (e:Dynamic) {
					throw 'Could not write to $devfile';
				}
			}

		}
	}
}
