package haxelib.client.commands;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

import haxelib.client.Cli;
import haxelib.client.Command;

class ConvertXml implements Command {
	public var name : String = "convertxml";
	public var alias : Array<String> = [];
	public var help : String = "convert haxelib.xml file to haxelib.json";
	public var category : CommandCategory = Miscellaneous;
	public var net : Bool = false;

	public function run (haxelib:Main) : Void {
		var cwd = Sys.getCwd();
		var xmlFile = cwd + "haxelib.xml";
		var jsonFile = cwd + "haxelib.json";

		if (!FileSystem.exists(xmlFile)) {
			Cli.print('No `haxelib.xml` file was found in the current directory.');
			Sys.exit(0);
		}

		var xmlString = File.getContent(xmlFile);
		var json = ConvertXml.convert(xmlString);
		var jsonString = ConvertXml.prettyPrint(json);

		File.saveContent(jsonFile, jsonString);
		Cli.print('Saved to $jsonFile');
	}

	public static function convert(inXml:String) {
		// Set up the default JSON structure
		var json = {
			"name": "",
			"url" : "",
			"license": "",
			"tags": [],
			"description": "",
			"version": "0.0.1",
			"releasenote": "",
			"contributors": [],
			"dependencies": {}
		};

		// Parse the XML and set the JSON
		var xml = Xml.parse(inXml);
		var project = xml.firstChild();
		json.name = project.get("name");
		json.license = project.get("license");
		json.url = project.get("url");
		for (node in project) {
			switch (node.nodeType) {
				case #if (haxe_ver >= 3.2) Element #else Xml.Element #end:
					switch (node.nodeName) {
						case "tag":
							json.tags.push(node.get("v"));
						case "user":
							json.contributors.push(node.get("name"));
						case "version":
							json.version = node.get("name");
							json.releasenote = node.firstChild().toString();
						case "description":
							json.description = node.firstChild().toString();
						case "depends":
							var name = node.get("name");
							var version = node.get("version");
							if (version == null) version = "";
							Reflect.setField(json.dependencies, name, version);
						default:
					}
				default:
			}
		}

		return json;
	}

	public static function prettyPrint(json:Dynamic, indent="") {
		var sb = new StringBuf();
		sb.add("{\n");

		var firstRun = true;
		for (f in Reflect.fields(json)) {
			if (!firstRun) sb.add(",\n");
			firstRun = false;

			var value = switch (f) {
				case "dependencies":
					var d = Reflect.field(json, f);
					prettyPrint(d, indent + "  ");
				default:
					Json.stringify(Reflect.field(json, f));
			}
			sb.add(indent+'  "$f": $value');
		}

		sb.add('\n$indent}');
		return sb.toString();
	}
}
