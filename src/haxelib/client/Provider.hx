package haxelib.client;

interface Provider {
	function canInstall (uri:String) : Bool;
	function doInstall (uri:String) : Void;
}
