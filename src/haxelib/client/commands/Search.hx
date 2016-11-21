package haxelib.client.commands;

import haxelib.client.Cli;
import haxelib.client.Command;

class Search implements Command {
	public var name : String = "search";
	public var alias : Array<String> = [];
	public var help : String = "list libraries matching a word";
	public var category : CommandCategory = Information;
	public var net : Bool = true;

	public function run (haxelib:Main) : Void {
		var word = haxelib.cli.param("Search word");
		var l = haxelib.site.search(word);
		for( s in l )
			Cli.print(s.name);
		Cli.print(l.length+" libraries found");
	}
}
