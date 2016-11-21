package haxelib.client.commands;

import haxelib.client.Cli;
import haxelib.client.Command;

using haxelib.Data;

class Info implements Command {
	public var name : String = "info";
	public var alias : Array<String> = [];
	public var help : String = "list information on a given library";
	public var category : CommandCategory = Information;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var prj = haxelib.cli.param("Library name");
		var inf = haxelib.site.infos(prj);
		Cli.print("Name: "+inf.name);
		Cli.print("Tags: "+inf.tags.join(", "));
		Cli.print("Desc: "+inf.desc);
		Cli.print("Website: "+inf.website);
		Cli.print("License: "+inf.license);
		Cli.print("Owner: "+inf.owner);
		Cli.print("Version: "+inf.getLatest());
		Cli.print("Releases: ");
		if( inf.versions.length == 0 )
			Cli.print("  (no version released yet)");
		for( v in inf.versions )
			Cli.print("   "+v.date+" "+v.name+" : "+v.comments);
	}
}
