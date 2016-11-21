package haxelib.client.commands;

import haxelib.client.Cli;
import haxelib.client.Command;

using StringTools;

class Help implements Command {
	public var name : String = "help";
	public var alias : Array<String> = [];
	public var help : String = "display this list of options";
	public var category : CommandCategory = Information;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var cats = [];
		var maxLength = 0;
		for( c in haxelib.commands ) {
			if (c.name.length > maxLength) maxLength = c.name.length;
			if (c.category.match(Deprecated(_))) continue;
			var i = c.category.getIndex();
			if (cats[i] == null) cats[i] = [c];
			else cats[i].push(c);
		}

		Cli.print("Haxe Library Manager " + Main.VERSION + " - (c)2006-2016 Haxe Foundation");
		Cli.print("  Usage: haxelib [command] [options]");

		for (cat in cats) {
			Cli.print("  " + cat[0].category.getName());
			for (c in cat) {
				Cli.print("    " + StringTools.rpad(c.name, " ", maxLength) + ": " + c.help);
			}
		}

		Cli.print("  Available switches");
		for (f in Reflect.fields(Main.ABOUT_SETTINGS))
			Cli.print('    --' + f.rpad(' ', maxLength-2) + ": " + Reflect.field(Main.ABOUT_SETTINGS, f));
	}
}
