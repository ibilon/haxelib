package haxelib.client;

interface Command {
	var name : String;
	var alias : Array<String>;
	var help : String;
	var category : CommandCategory;
	var net : Bool;
	function run (haxelib:Main) : Void;
}

enum CommandCategory {
	Basic;
	Information;
	Development;
	Miscellaneous;
	Deprecated(msg:String);
}
