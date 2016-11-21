package haxelib.client.commands;

import haxe.io.BytesOutput;
import haxe.zip.*;
import sys.FileSystem;
import sys.io.File;

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

		var user:String = infos.contributors[0];

		if (infos.contributors.length > 1)
			do {
				Cli.print("Which of these users are you: " + infos.contributors);
				user = haxelib.cli.param("User");
			} while ( infos.contributors.indexOf(user) == -1 );

		var password;
		if( haxelib.site.isNewUser(user) ) {
			Cli.print("This is your first submission as '"+user+"'");
			Cli.print("Please enter the following informations for registration");
			password = Register.doRegister(haxelib, user);
		} else {
			password = haxelib.cli.readPassword(haxelib.site, user);
		}
		haxelib.site.checkDeveloper(infos.name,user);

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

		// query a submit id that will identify the file
		var id = haxelib.site.getSubmitId();

		// directly send the file data over Http
		var h = haxelib.createHttpRequest("http://"+Main.SERVER.host+":"+Main.SERVER.port+"/"+Main.SERVER.url);
		h.onError = function(e) throw e;
		h.onData = Cli.print;
		h.fileTransfer("file",id,new ProgressIn(new haxe.io.BytesInput(data),data.length),data.length);
		Cli.print("Sending data.... ");
		h.request(true);

		// processing might take some time, make sure we wait
		Cli.print("Processing file.... ");
		if (haxe.remoting.HttpConnection.TIMEOUT != 0) // don't ignore -notimeout
			haxe.remoting.HttpConnection.TIMEOUT = 1000;
		// ask the server to register the sent file
		var msg = haxelib.site.processSubmit(id,user,password);
		Cli.print(msg);
	}
}
