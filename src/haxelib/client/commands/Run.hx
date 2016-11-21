package haxelib.client.commands;

import sys.FileSystem;
import sys.io.File;

import haxelib.Data;
import haxelib.client.Command;

class Run implements Command {
	public var name : String = "run";
	public var alias : Array<String> = [];
	public var help : String = "run the specified library with parameters";
	public var category : CommandCategory = Miscellaneous;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var rep = haxelib.getRepository();
		var project = haxelib.cli.param("Library");
		var temp = project.split(":");
		doRun(haxelib, rep, temp[0], temp[1]);
	}

	public static function doRun (haxelib:Main, rep:String, project:String, version:String ) {
		var pdir = rep + Data.safe(project);
		if( !FileSystem.exists(pdir) )
			throw "Library "+project+" is not installed";
		pdir += "/";
		if (version == null)
			version = haxelib.getCurrent(pdir);
		var dev = try haxelib.getDev(pdir) catch ( e : Dynamic ) null;
		var vdir = dev != null ? dev : pdir + Data.safe(version);

		var infos =
			try
				Data.readData(File.getContent(vdir + '/haxelib.json'), false)
			catch (e:Dynamic)
				throw 'Error parsing haxelib.json for $project@$version: $e';

		var args = [];
		while (haxelib.cli.hasNext())
			args.push(haxelib.cli.next());

		args.push(Sys.getCwd());
		Sys.setCwd(vdir);

		var callArgs =
			if (infos.main == null) {
				if( !FileSystem.exists('$vdir/run.n') )
					throw 'Library $project version $version does not have a run script';
				["neko", vdir + "/run.n"];
			} else {
				var deps = infos.dependencies.toArray();
				deps.push( { name: project, version: DependencyVersion.DEFAULT } );
				var args = [];
				for (d in deps) {
					args.push('-lib');
					args.push(d.name + if (d.version == '') '' else ':${d.version}');
				}
				args.unshift('haxe');
				args.push('--run');
				args.push(infos.main);
				args;
			}

		for (i in 0...args.length)
			callArgs.push(args[i]);

		Sys.putEnv("HAXELIB_RUN", "1");
		Sys.putEnv("HAXELIB_RUN_NAME", project);
		var cmd = callArgs.shift();
 		Sys.exit(Sys.command(cmd, callArgs));
	}
}
