/*
 * Copyright (C)2005-2016 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package haxelib.client;

import haxe.crypto.Md5;
import haxe.*;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import sys.io.*;
import haxe.ds.Option;
import haxelib.client.Cli.ask;
import haxelib.client.FsUtils.*;
import haxelib.client.Vcs;

using StringTools;
using Lambda;
using haxelib.Data;

class Main {
	public static inline var HAXELIB_LIBNAME = "haxelib";

	public static var VERSION = SemVer.ofString('3.4.0');
	public static var REPODIR = ".haxelib";
	static var REPNAME = "lib";
	public static var SERVER = {
		host : "lib.haxe.org",
		port : 80,
		dir : "",
		url : "index.n",
		apiVersion : "3.0",
	};
	static var IS_WINDOWS = (Sys.systemName() == "Windows");

	public var cli : Cli;
	public var site : SiteProxy;
	public var commands : Array<Command>;
	public var siteUrl : String;
	public var isHaxelibRun : Bool;
	public var alreadyUpdatedVcsDependencies : Map<String,String> = new Map<String,String>();

	function new() {
		var args = Sys.args();
		isHaxelibRun = (Sys.getEnv("HAXELIB_RUN_NAME") == HAXELIB_LIBNAME);

		if (isHaxelibRun)
			Sys.setCwd(args.pop());

		CompileTime.importPackage("haxelib.client.commands");
		commands = [for (c in CompileTime.getAllClasses(Command)) Type.createInstance(c, [])];

		cli = new Cli(args);
	}

	function checkUpdate() {
		var latest = try site.getLatestVersion(HAXELIB_LIBNAME) catch (_:Dynamic) null;
		if (latest != null && latest > VERSION)
			Cli.print('\nA new version ($latest) of haxelib is available.\nDo `haxelib --global update $HAXELIB_LIBNAME` to get the latest version.\n');
	}

	function initSite() {
		siteUrl = "http://" + SERVER.host + ":" + SERVER.port + "/" + SERVER.dir;
		var remotingUrl =  siteUrl + "api/" + SERVER.apiVersion + "/" + SERVER.url;
		site = new SiteProxy(haxe.remoting.HttpConnection.urlConnect(remotingUrl).api);
	}

	public static var ABOUT_SETTINGS = {
		global : "force global repo if a local one exists",
		debug  : "run in debug mode, imply not --quiet",
		quiet  : "print less messages, imply not --debug",
		flat   : "do not use --recursive cloning for git",
		always : "answer all questions with yes",
		never  : "answer all questions with no",
		system : "run bundled haxelib version instead of latest update",
	}

	public var settings: {
		debug  : Bool,
		quiet  : Bool,
		flat   : Bool,
		always : Bool,
		never  : Bool,
		global : Bool,
		system : Bool,
	};

	public function getCommand (cmd:String) : Command {
		for (c in commands) {
			if (c.name == cmd || c.alias.indexOf(cmd) > -1) {
				return c;
			}
		}

		Cli.print("Unknown command "+cmd);
		Sys.exit(1);
		return null;
	}

	public function process() {
		var cmd = "help";

		settings = {
			debug: false,
			quiet: false,
			always: false,
			never: false,
			flat: false,
			global: false,
			system: false,
		};

		function parseSwitch(s:String) {
			return
				if (s.startsWith('--'))
					Some(s.substr(2));
				else if (s.startsWith('-'))
					Some(s.substr(1));
				else
					None;
		}

		for (a in cli) {
			switch (a) {
				case "-cwd":
					if (!cli.hasNext()) {
						Cli.print("Missing directory argument for -cwd");
						Sys.exit(1);
					}
					var dir = cli.next();
					try {
						Sys.setCwd(dir);
					} catch (e:String) {
						if (e == "std@set_cwd") {
							Cli.print("Directory " + dir + " unavailable");
							Sys.exit(1);
						}
						neko.Lib.rethrow(e);
					}
				case "-notimeout":
					haxe.remoting.HttpConnection.TIMEOUT = 0;
				case "-R":
					if (!cli.hasNext()) {
						Cli.print("Missing url argument for -R");
						Sys.exit(1);
					}
					var path = cli.next();
					var r = ~/^(http:\/\/)?([^:\/]+)(:[0-9]+)?\/?(.*)$/;
					if( !r.match(path) )
						throw "Invalid repository format '"+path+"'";
					SERVER.host = r.matched(2);
					if( r.matched(3) != null )
						SERVER.port = Std.parseInt(r.matched(3).substr(1));
					SERVER.dir = r.matched(4);
					if (SERVER.dir.length > 0 && !SERVER.dir.endsWith("/")) SERVER.dir += "/";
					initSite();
				case "--debug":
					settings.debug = true;
					settings.quiet = false;
				case "--quiet":
					settings.debug = false;
					settings.quiet = true;
				case parseSwitch(_) => Some(s):
					if (!Reflect.hasField(settings, s)) {
						Cli.print('Unknown switch $a');
						Sys.exit(1);
					}
					Reflect.setField(settings, s, true);
				default:
					cmd = a;
					break;
			}
		}

		if (!isHaxelibRun && !settings.system) {
			var rep = try getGlobalRepository() catch (_:Dynamic) null;
			if (rep != null && FileSystem.exists(rep + HAXELIB_LIBNAME)) {
				cli.reset(); // send all arguments
				haxelib.client.commands.Run.doRun(this, rep, HAXELIB_LIBNAME, null);
				return;
			}
		}

		Cli.defaultAnswer =
			switch [settings.always, settings.never] {
				case [true, true]:
					Cli.print('--always and --never are mutually exclusive');
					Sys.exit(1);
					null;
				case [true, _]: true;
				case [_, true]: false;
				default: null;
			}

		var c = getCommand(cmd);
		switch (c.category) {
			case Deprecated(message):
				Cli.print('Warning: Command `$cmd` is deprecated and will be removed in future. $message.');
			default:
		}
		try {
			if( c.net ) {
				loadProxy();
				initSite();
				checkUpdate();
			}
			c.run(this);
		} catch( e : Dynamic ) {
			if( e == "std@host_resolve" ) {
				Cli.print("Host "+SERVER.host+" was not found");
				Cli.print("Please ensure that your internet connection is on");
				Cli.print("If you don't have an internet connection or if you are behing a proxy");
				Cli.print("please download manually the file from http://lib.haxe.org/files/3.0/");
				Cli.print("and run 'haxelib install <file>' to install the Library.");
				Cli.print("You can also setup the proxy with 'haxelib proxy'.");
				Sys.exit(1);
			}
			if( e == "Blocked" ) {
				Cli.print("Http connection timeout. Try running haxelib -notimeout <command> to disable timeout");
				Sys.exit(1);
			}
			if( e == "std@get_cwd" ) {
				Cli.print("Error: Current working directory is unavailable");
				Sys.exit(1);
			}
			if( settings.debug )
				neko.Lib.rethrow(e);
			Cli.print("Error: " + Std.string(e));
			Sys.exit(1);
		}
	}

	inline public function createHttpRequest(url:String):Http {
		var req = new Http(url);
		if (haxe.remoting.HttpConnection.TIMEOUT == 0)
			req.cnxTimeout = 0;
		return req;
	}

	// ---- COMMANDS --------------------

	public function getVersion( inf:ProjectInfos, ?reqversion:String ) {
		if( inf.versions.length == 0 )
			throw "The library "+inf.name+" has not yet released a version";
		var version = if( reqversion != null ) reqversion else inf.getLatest();
		var found = false;
		for( v in inf.versions )
			if( v.name == version ) {
				found = true;
				break;
			}
		if( !found )
			throw "No such version "+version+" for library "+inf.name;

		return version;
	}

	public function getConfigFile():String {
		var home = null;
		if (IS_WINDOWS) {
			home = Sys.getEnv("USERPROFILE");
			if (home == null) {
				var drive = Sys.getEnv("HOMEDRIVE");
				var path = Sys.getEnv("HOMEPATH");
				if (drive != null && path != null)
					home = drive + path;
			}
			if (home == null)
				throw "Could not determine home path. Please ensure that USERPROFILE or HOMEDRIVE+HOMEPATH environment variables are set.";
		} else {
			home = Sys.getEnv("HOME");
			if (home == null)
				throw "Could not determine home path. Please ensure that HOME environment variable is set.";
		}
		return Path.addTrailingSlash(home) + ".haxelib";
	}

	public function getGlobalRepositoryPath(create = false):String {
		// first check the env var
		var rep = Sys.getEnv("HAXELIB_PATH");
		if (rep != null)
			return rep.trim();

		// try to read from user config
		rep = try File.getContent(getConfigFile()).trim() catch (_:Dynamic) null;
		if (rep != null)
			return rep;

		if (!IS_WINDOWS) {
			// on unixes, try to read system-wide config
			rep = try File.getContent("/etc/.haxelib").trim() catch (_:Dynamic) null;
			if (rep == null)
				throw "This is the first time you are runing haxelib. Please run `haxelib setup` first";
		} else {
			// on windows, try to use haxe installation path
			rep = getWindowsDefaultGlobalRepositoryPath();
			if (create)
				try safeDir(rep) catch(e:Dynamic) throw 'Error accessing Haxelib repository: $e';
		}

		return rep;
	}

	// on windows we have default global haxelib path - where haxe is installed
	public function getWindowsDefaultGlobalRepositoryPath():String {
		var haxepath = Sys.getEnv("HAXEPATH");
		if (haxepath == null)
			throw "HAXEPATH environment variable not defined, please run haxesetup.exe first";
		return Path.addTrailingSlash(haxepath.trim()) + REPNAME;
	}

	public function getSuggestedGlobalRepositoryPath():String {
		if (IS_WINDOWS)
			return getWindowsDefaultGlobalRepositoryPath();

		return if (FileSystem.exists("/usr/share/haxe")) // for Debian
			'/usr/share/haxe/$REPNAME'
		else if (Sys.systemName() == "Mac") // for newer OSX, where /usr/lib is not writable
			'/usr/local/lib/haxe/$REPNAME'
		else
			'/usr/lib/haxe/$REPNAME'; // for other unixes
	}

	public function getRepository():String {
		if (!settings.global && FileSystem.exists(REPODIR) && FileSystem.isDirectory(REPODIR))
			return Path.addTrailingSlash(FileSystem.fullPath(REPODIR));
		else
			return getGlobalRepository();
	}

	public function getGlobalRepository():String {
		var rep = getGlobalRepositoryPath(true);
		if (!FileSystem.exists(rep))
			throw "haxelib Repository " + rep + " does not exist. Please run `haxelib setup` again.";
		else if (!FileSystem.isDirectory(rep))
			throw "haxelib Repository " + rep + " exists, but is a file, not a directory. Please remove it and run `haxelib setup` again.";
		return Path.addTrailingSlash(rep);
	}

	public function getCurrent( dir ) {
		return (FileSystem.exists(dir+"/.dev")) ? "dev" : File.getContent(dir + "/.current").trim();
	}

	public function getDev( dir ) {
		return File.getContent(dir + "/.dev").trim();
	}

	public function projectNameToDir( rep:String, project:String ) {
		var p = project.toLowerCase();
		var l = FileSystem.readDirectory(rep).filter(function (dir) return dir.toLowerCase() == p);

		switch (l) {
			case []: return project;
			case [dir]: return Data.unsafe(dir);
			case _: throw "Several name case for library " + project;
		}
	}

	public function setCurrent( rep : String, prj : String, version : String, doAsk : Bool ) {
		var pdir = rep + Data.safe(prj);
		var vdir = pdir + "/" + Data.safe(version);
		if( !FileSystem.exists(vdir) ){
			Cli.print("Library "+prj+" version "+version+" is not installed");
			if(ask("Would you like to install it?"))
				haxelib.client.commands.Install.doInstall(this, rep, prj, version, true);
			return;
		}
		if( File.getContent(pdir + "/.current").trim() == version )
			return;
		if( doAsk && !ask("Set "+prj+" to version "+version) )
			return;
		File.saveContent(pdir+"/.current",version);
		Cli.print("Library "+prj+" current version is now "+version);
	}

	public function checkRec( rep : String, prj : String, version : String, l : Array<{ project : String, version : String, dir : String, info : Infos }> ) {
		var pdir = rep + Data.safe(prj);
		if( !FileSystem.exists(pdir) )
			throw "Library "+prj+" is not installed : run 'haxelib install "+prj+"'";
		var version = if( version != null ) version else getCurrent(pdir);

		var dev = try getDev(pdir) catch (_:Dynamic) null;
		var vdir = if (dev != null) dev else pdir + "/" + Data.safe(version);

		if( !FileSystem.exists(vdir) )
			throw "Library "+prj+" version "+version+" is not installed";

		for( p in l )
			if( p.project == prj ) {
				if( p.version == version )
					return;
				throw "Library "+prj+" has two version included "+version+" and "+p.version;
			}
		var json = try File.getContent(vdir+"/"+Data.JSON) catch( e : Dynamic ) null;
		var inf = Data.readData(json,false);
		l.push({ project : prj, version : version, dir : Path.addTrailingSlash(vdir), info: inf });
		for( d in inf.dependencies )
			if( !Lambda.exists(l, function(e) return e.project == d.name) )
				checkRec(rep,d.name,if( d.version == "" ) null else d.version,l);
	}

	public function removeExistingDevLib(proj:String):Void {
		//TODO: ask if existing repo have changes.

		// find existing repo:
		var vcs = Vcs.getVcsForDevLib(proj, settings);
		// remove existing repos:
		while(vcs != null) {
			deleteRec(proj + "/" + vcs.directory);
			vcs = Vcs.getVcsForDevLib(proj, settings);
		}
	}

	function loadProxy() {
		var rep = getRepository();
		try Http.PROXY = haxe.Unserializer.run(File.getContent(rep + "/.proxy")) catch( e : Dynamic ) { };
	}

	// ----------------------------------

	static function main() {
		new Main().process();
	}
}
