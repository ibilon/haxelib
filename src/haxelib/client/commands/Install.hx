package haxelib.client.commands;

import haxe.zip.*;
import sys.FileSystem;
import sys.io.File;

import haxelib.client.Command;
import haxelib.client.FsUtils;

using StringTools;
using haxelib.Data;

class Install implements Command {
	public var name : String = "install";
	public var alias : Array<String> = [];
	public var help : String = "install a given library, or all libraries from a hxml file";
	public var category : CommandCategory = Basic;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var rep = haxelib.getRepository();

		var prj = haxelib.cli.param("Library name or hxml file:");

		// No library given, install libraries listed in *.hxml in given directory
		if( prj == "all") {
			installFromAllHxml(haxelib, rep);
			return;
		}

		if( sys.FileSystem.exists(prj) && !sys.FileSystem.isDirectory(prj) ) {
			// *.hxml provided, install all libraries/versions in this hxml file
			if( prj.endsWith(".hxml") ) {
				installFromHxml(haxelib, rep, prj);
				return;
			}
			// *.zip provided, install zip as haxe library
			if (prj.endsWith(".zip")) {
				doInstallFile(haxelib, rep, prj, true, true);
				return;
			}

			if ( prj.endsWith("haxelib.json") )
			{
				installFromHaxelibJson(haxelib, rep, prj);
				return;
			}
		}

		// Name provided that wasn't a local hxml or zip, so try to install it from server
		var inf = haxelib.site.infos(prj);
		var reqversion = haxelib.cli.paramOpt();
		var version = haxelib.getVersion(inf, reqversion);
		doInstall(haxelib, rep,inf.name,version,version == inf.getLatest());
	}

	public static function installFromHxml (haxelib:Main, rep:String, path:String ) {
		var targets  = [
			'-java ' => 'hxjava',
			'-cpp ' => 'hxcpp',
			'-cs ' => 'hxcs',
		];
		var libsToInstall = new Map<String, {name:String,version:String,type:String,url:String,branch:String,subDir:String}>();

		function processHxml(path) {
			var hxml = sys.io.File.getContent(path);
			var lines = hxml.split("\n");
			for (l in lines) {
				l = l.trim();
				for (target in targets.keys())
					if (l.startsWith(target)) {
						var lib = targets[target];
						if (!libsToInstall.exists(lib))
							libsToInstall[lib] = { name: lib, version: null, type:"haxelib", url: null, branch: null, subDir: null }
					}

				if (l.startsWith("-lib"))
				{
					var key = l.substr(5).trim();
					var parts = ~/:/.split(key);
					var libName = parts[0];
					var libVersion:String = null;
					var branch:String = null;
					var url:String = null;
					var subDir:String = null;
					var type:String;

					if ( parts.length > 1 )
					{
						if ( parts[1].startsWith("git:") )
						{

							type = "git";
							var urlParts = parts[1].substr(4).split("#");
							url = urlParts[0];
							branch = urlParts.length > 1 ? urlParts[1] : null;
						}
						else
						{
							type = "haxelib";
							libVersion = parts[1];
						}
					}
					else
					{
						type = "haxelib";
					}

					switch libsToInstall[key] {
						case null, { version: null } :
							libsToInstall.set(key, { name:libName, version:libVersion, type: type, url: url, subDir: subDir, branch: branch } );
						default:
					}
				}

				if (l.endsWith(".hxml"))
					processHxml(l);
			}
		}
		processHxml(path);

		if (Lambda.empty(libsToInstall))
			return;

		// Check the version numbers are all good
		// TODO: can we collapse this into a single API call?  It's getting too slow otherwise.
		Cli.print("Loading info about the required libraries");
		for (l in libsToInstall)
		{
			if ( l.type == "git" )
			{
				// Do not check git repository infos
				continue;
			}
			var inf = haxelib.site.infos(l.name);
			l.version = haxelib.getVersion(inf, l.version);
		}

		// Print a list with all the info
		Cli.print("Haxelib is going to install these libraries:");
		for (l in libsToInstall) {
			var vString = (l.version == null) ? "" : " - " + l.version;
			Cli.print("  " + l.name + vString);
		}

		// Install if they confirm
		if (Cli.ask("Continue?")) {
			for (l in libsToInstall) {
				if ( l.type == "haxelib" )
					doInstall(haxelib, rep, l.name, l.version, true);
				else if ( l.type == "git" )
					Vcs.useVcs(haxelib, Git, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, l.name, l.url, l.branch, l.subDir, l.version));
				else if ( l.type == "hg" )
					Vcs.useVcs(haxelib, Hg, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, l.name, l.url, l.branch, l.subDir, l.version));
			}
		}
	}

	public static function installFromHaxelibJson (haxelib:Main, rep:String, path:String )
	{
		doInstallDependencies(haxelib, rep, Data.readData(File.getContent(path), false).dependencies);
	}

	public static function installFromAllHxml (haxelib:Main, rep:String) {
		var cwd = Sys.getCwd();
		var hxmlFiles = sys.FileSystem.readDirectory(cwd).filter(function (f) return f.endsWith(".hxml"));
		if (hxmlFiles.length > 0) {
			for (file in hxmlFiles) {
				Cli.print('Installing all libraries from $file:');
				installFromHxml(haxelib, rep, cwd + file);
			}
		} else {
			Cli.print("No hxml files found in the current directory.");
		}
	}

	public static function doInstall (haxelib:Main, rep, project, version, setcurrent ) {
		// check if exists already
		if( FileSystem.exists(rep+Data.safe(project)+"/"+Data.safe(version)) ) {
			Cli.print("You already have "+project+" version "+version+" installed");
			haxelib.setCurrent(rep,project,version,true);
			return;
		}

		// download to temporary file
		var filename = Data.fileName(project,version);
		var filepath = rep+filename;
		var out = try File.append(filepath,true) catch (e:Dynamic) throw 'Failed to write to $filepath: $e';
		out.seek(0, SeekEnd);

		var h = haxelib.createHttpRequest(haxelib.siteUrl+Data.REPOSITORY+"/"+filename);

		var currentSize = out.tell();
		if (currentSize > 0)
			h.addHeader("range", "bytes="+currentSize + "-");

		var progress = new ProgressOut(out, currentSize);

		var has416Status = false;
		h.onStatus = function(status) {
			// 416 Requested Range Not Satisfiable, which means that we probably have a fully downloaded file already
			if (status == 416) has416Status = true;
		};
		h.onError = function(e) {
			progress.close();

			// if we reached onError, because of 416 status code, it's probably okay and we should try unzipping the file
			if (!has416Status) {
				FileSystem.deleteFile(filepath);
				throw e;
			}
		};
		Cli.print("Downloading "+filename+"...");
		h.customRequest(false,progress);

		doInstallFile(haxelib, rep,filepath, setcurrent);
		try {
			haxelib.site.postInstall(project, version);
		} catch (e:Dynamic) {}
	}

	public static function doInstallFile (haxelib:Main, rep,filepath,setcurrent,nodelete = false) {
		// read zip content
		var f = File.read(filepath,true);
		var zip = try {
			Reader.readZip(f);
		} catch (e:Dynamic) {
			f.close();
			// file is corrupted, remove it
			if (!nodelete)
				FileSystem.deleteFile(filepath);
			neko.Lib.rethrow(e);
			throw e;
		}
		f.close();
		var infos = Data.readInfos(zip,false);
		Cli.print('Installing ${infos.name}...');
		// create directories
		var pdir = rep + Data.safe(infos.name);
		FsUtils.safeDir(pdir);
		pdir += "/";
		var target = pdir + Data.safe(infos.version);
		FsUtils.safeDir(target);
		target += "/";

		// locate haxelib.json base path
		var basepath = Data.locateBasePath(zip);

		// unzip content
		var entries = [for (entry in zip) if (entry.fileName.startsWith(basepath)) entry];
		var total = entries.length;
		for (i in 0...total) {
			var zipfile = entries[i];
			var n = zipfile.fileName;
			// remove basepath
			n = n.substr(basepath.length,n.length-basepath.length);
			if( n.charAt(0) == "/" || n.charAt(0) == "\\" || n.split("..").length > 1 )
				throw "Invalid filename : "+n;

			if (!haxelib.settings.debug) {
				var percent = Std.int((i / total) * 100);
				Sys.print('${i + 1}/$total ($percent%)\r');
			}

			var dirs = ~/[\/\\]/g.split(n);
			var path = "";
			var file = dirs.pop();
			for( d in dirs ) {
				path += d;
				FsUtils.safeDir(target+path);
				path += "/";
			}
			if( file == "" ) {
				if( path != "" && haxelib.settings.debug )
					Cli.print("  Created "+path);
				continue; // was just a directory
			}
			path += file;
			if (haxelib.settings.debug)
				Cli.print("  Install "+path);
			var data = Reader.unzip(zipfile);
			File.saveBytes(target+path,data);
		}

		// set current version
		if( setcurrent || !FileSystem.exists(pdir+".current") ) {
			File.saveContent(pdir + ".current", infos.version);
			Cli.print("  Current version is now "+infos.version);
		}

		// end
		if( !nodelete )
			FileSystem.deleteFile(filepath);
		Cli.print("Done");

		// process dependencies
		doInstallDependencies(haxelib, rep, infos.dependencies);

		return infos;
	}

	public static function doInstallDependencies (haxelib:Main, rep:String, dependencies:Array<Dependency> ) {
		for( d in dependencies ) {
			if( d.version == "" ) {
				var pdir = rep + Data.safe(d.name);
				var dev = try haxelib.getDev(pdir) catch (_:Dynamic) null;

				if (dev != null) { // no version specified and dev set, no need to install dependency
					continue;
				}
			}

			if( d.version == "" && d.type == DependencyType.Haxelib )
				d.version = haxelib.site.getLatestVersion(d.name);
			Cli.print("Installing dependency "+d.name+" "+d.version);

			switch d.type {
				case Haxelib:
					doInstall(haxelib, rep, d.name, d.version, false);
				case Git:
					Vcs.useVcs(haxelib, Git, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, d.name, d.url, d.branch, d.subDir, d.version));
				case Mercurial:
					Vcs.useVcs(haxelib, Hg, function(vcs) Vcs.doVcsInstall(haxelib, rep, vcs, d.name, d.url, d.branch, d.subDir, d.version));
			}
		}
	}
}
