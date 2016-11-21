package haxelib.client.commands;

import sys.FileSystem;
import sys.io.File;

import haxelib.client.Cli;
import haxelib.client.Command;
import haxelib.client.FsUtils;

class Setup implements Command {
	public var name : String = "setup";
	public var alias : Array<String> = [];
	public var help : String = "set the haxelib repository path";
	public var category : CommandCategory = Miscellaneous;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var rep = try haxelib.getGlobalRepositoryPath() catch (_:Dynamic) null;
		if (rep == null)
			rep = haxelib.getSuggestedGlobalRepositoryPath();

		var configFile = haxelib.getConfigFile();

		if (!haxelib.cli.hasNext()) {
			Cli.print("Please enter haxelib repository path with write access");
			Cli.print("Hit enter for default (" + rep + ")");
		}

		var line = haxelib.cli.param("Path");
		if (line != "")
			rep = line;

		rep = try FileSystem.fullPath(rep) catch (_:Dynamic) rep;

		if (FsUtils.isSamePath(rep, configFile))
			throw "Can't use "+rep+" because it is reserved for config file";

		FsUtils.safeDir(rep);
		File.saveContent(configFile, rep);

		Cli.print("haxelib repository is now " + rep);
	}
}
