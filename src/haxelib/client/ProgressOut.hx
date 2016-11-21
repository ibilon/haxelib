package haxelib.client;

import haxe.Timer;
import haxe.io.Output;

class ProgressOut extends Output {
	var o : Output;
	var cur : Int;
	var startSize : Int;
	var max : Null<Int>;
	var start : Float;

	public function new(o, currentSize) {
		this.o = o;
		startSize = currentSize;
		cur = currentSize;
		start = Timer.stamp();
	}

	function report(n) {
		cur += n;
		if( max == null )
			Sys.print(cur+" bytes\r");
		else
			Sys.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		report(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		report(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = Timer.stamp() - start;
		var downloadedBytes = cur - startSize;
		var speed = (downloadedBytes / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		Sys.print("Download complete : "+downloadedBytes+" bytes in "+time+"s ("+speed+"KB/s)\n");
	}

	public override function prepare(m) {
		max = m + startSize;
	}
}
