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
		var rep = haxelib.getRepository();
		var project = haxelib.cli.param("Library");
		var dir = haxelib.cli.paramOpt();
		var proj = rep + Data.safe(project);
		if( !FileSystem.exists(proj) ) {
			FileSystem.createDirectory(proj);
		}
		var devfile = proj+"/.dev";
		if( dir == null ) {
			if( FileSystem.exists(devfile) )
				FileSystem.deleteFile(devfile);
			Cli.print("Development directory disabled");
		}
		else {
			while ( dir.endsWith("/") || dir.endsWith("\\") ) {
				dir = dir.substr(0,-1);
			}
			if (!FileSystem.exists(dir)) {
				Cli.print('Directory $dir does not exist');
			} else {
				dir = FileSystem.fullPath(dir);
				try {
					File.saveContent(devfile, dir);
					Cli.print("Development directory set to "+dir);
				}
				catch (e:Dynamic) {
					Cli.print('Could not write to $devfile');
				}
			}

		}
	}
}
