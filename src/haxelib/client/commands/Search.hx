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
		var list = doSearch(haxelib, word);
		for (l in list) {
			Cli.print(l.name);
		}
		Cli.print(list.length+" libraries found");
	}

	public static function doSearch (haxelib:Main, word:String) {
		return haxelib.site.search(word);
	}
}
