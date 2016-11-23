package haxelib.client.commands;

import sys.FileSystem;

import haxelib.client.Cli;
import haxelib.client.Command;

class List implements Command {
	public var name : String = "list";
	public var alias : Array<String> = [];
	public var help : String = "list all installed libraries";
	public var category : CommandCategory = Basic;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var filter = haxelib.cli.paramOpt();
		var list = doList(haxelib, filter);

		for (p in list) {
			Cli.print(p);
		}
	}

	public static function doList (haxelib:Main, filter:String) {
		var rep = haxelib.getRepository();
		var folders = FileSystem.readDirectory(rep);

		if ( filter != null )
			folders = folders.filter( function (f) return f.toLowerCase().indexOf(filter.toLowerCase()) > -1 );
		var all = [];
		for( p in folders ) {
			if( p.charAt(0) == "." )
				continue;

			var current = try haxelib.getCurrent(rep + p) catch(e:Dynamic) continue;
			var dev = try haxelib.getDev(rep + p) catch( e : Dynamic ) null;

			var semvers = [];
			var others = [];
			for( v in FileSystem.readDirectory(rep+p) ) {
				if( v.charAt(0) == "." )
					continue;
				v = Data.unsafe(v);
				var semver = try SemVer.ofString(v) catch (_:Dynamic) null;
				if (semver != null)
					semvers.push(semver);
				else
					others.push(v);
			}

			if (semvers.length > 0)
				semvers.sort(SemVer.compare);

			var versions = [];
			for (v in semvers)
				versions.push((v : String));
			for (v in others)
				versions.push(v);

			if (dev == null) {
				for (i in 0...versions.length) {
					var v = versions[i];
					if (v == current)
						versions[i] = '[$v]';
				}
			} else {
				versions.push("[dev:"+dev+"]");
			}

			all.push(Data.unsafe(p) + ": "+versions.join(" "));
		}
		all.sort(function(s1, s2) return Reflect.compare(s1.toLowerCase(), s2.toLowerCase()));

		return all;
	}
}
