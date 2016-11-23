package haxelib.client.commands;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.*;
import sys.FileSystem;
import sys.io.File;

import haxelib.Data;
import haxelib.client.Cli;
import haxelib.client.Command;
import haxelib.client.FsUtils;

class Submit implements Command {
	public var name : String = "submit";
	public var alias : Array<String> = [];
	public var help : String = "submit or update a library package";
	public var category : CommandCategory = Development;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var file = haxelib.cli.param("Package");
		var infos = getInfos(haxelib, file);
		var user = infos.infos.contributors[0];

		if (infos.infos.contributors.length > 1)
			do {
				Cli.print("Which of these users are you: " + infos.infos.contributors);
				user = haxelib.cli.param("User");
			} while ( infos.infos.contributors.indexOf(user) == -1 );

		var password;
		if( haxelib.site.isNewUser(user) ) {
			Cli.print("This is your first submission as '"+user+"'");
			Cli.print("Please enter the following informations for registration");
			//TODO this is a copy from commands.Register.run
			var email = haxelib.cli.param("Email");
			var fullname = haxelib.cli.param("Fullname");
			var pass = haxelib.cli.param("Password", true);
			var pass2 = haxelib.cli.param("Confirm", true);
			if (pass != pass2) {
				Cli.print("Password does not match");
				Sys.exit(1);
			}
			password = Register.doRegister(haxelib, user, pass, email, fullname);
		} else {
			password = haxelib.cli.readPassword(haxelib.site, user);
		}

		doChecks(haxelib, infos.infos, user);

		Cli.print("Sending data.... ");
		var id = submit(haxelib, infos.data, Cli.print);

		Cli.print("Processing file.... ");
		var msg = processSubmit(haxelib, id, user, password);
		Cli.print(msg);
	}

	public static function getInfos (haxelib:Main, file:String) : { infos:Infos, data:Bytes } {
		var data, zip;
		if (FileSystem.isDirectory(file)) {
			zip = FsUtils.zipDirectory(file);
			var out = new BytesOutput();
			new Writer(out).write(zip);
			data = out.getBytes();
		} else {
			data = File.getBytes(file);
			zip = Reader.readZip(new haxe.io.BytesInput(data));
		}

		var infos = Data.readInfos(zip,true);
		Data.checkClassPath(zip, infos);

		return { infos: infos, data: data };
	}

	public static function doChecks (haxelib:Main, infos:Infos, user:String) {
		haxelib.site.checkDeveloper(infos.name, user);

		// check dependencies validity
		for( d in infos.dependencies ) {
			var infos = haxelib.site.infos(d.name);
			if( d.version == "" )
				continue;
			var found = false;
			for( v in infos.versions )
				if( v.name == d.version ) {
					found = true;
					break;
				}
			if( !found )
				throw "Library " + d.name + " does not have version " + d.version;
		}

		// check if this version already exists
		var sinfos = try haxelib.site.infos(infos.name) catch( _ : Dynamic ) null;
		if( sinfos != null )
			for( v in sinfos.versions )
				if( v.name == infos.version && !Cli.ask("You're about to overwrite existing version '"+v.name+"', please confirm") )
					throw "Aborted";
	}

	public static function submit (haxelib:Main, data:Bytes, onData:String->Void) {
		// query a submit id that will identify the file
		var id = haxelib.site.getSubmitId();

		// directly send the file data over Http
		var h = haxelib.createHttpRequest("http://"+Main.SERVER.host+":"+Main.SERVER.port+"/"+Main.SERVER.url);
		h.onError = function(e) throw e;
		h.onData = onData;
		h.fileTransfer("file", id, new ProgressIn(new haxe.io.BytesInput(data), data.length), data.length);
		h.request(true);

		return id;
	}

	public static function processSubmit (haxelib:Main, id:String, user:String, password:String) {
		// processing might take some time, make sure we wait
		if (haxe.remoting.HttpConnection.TIMEOUT != 0) // don't ignore -notimeout
			haxe.remoting.HttpConnection.TIMEOUT = 1000;

		// ask the server to register the sent file
		return haxelib.site.processSubmit(id, user, password);
	}
}
