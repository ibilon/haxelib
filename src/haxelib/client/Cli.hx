/*
 * Copyright (C)2005-2016 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package haxelib.client;

import haxe.crypto.Md5;

class Cli {
	public static var defaultAnswer:Null<Bool>;

	public static function ask(question:String):Bool {
		if (defaultAnswer != null)
			return defaultAnswer;

		while (true) {
			Sys.print(question + " [y/n/a] ? ");
			try {
				switch (Sys.stdin().readLine()) {
					case "n": return false;
					case "y": return true;
					case "a": return defaultAnswer = true;
				}
			} catch (e:haxe.io.Eof) {
				Sys.println("n");
				return false;
			}
		}
		return false;
	}

	inline public static function print (str:String) {
		Sys.println(str);
	}

	var args : Array<String>;
	var argcur : Int;

	public function new (args:Array<String>) {
		this.args = args;
		argcur = 0;
	}

	public function param (name, ?passwd) {
		if (args.length > argcur)
			return args[argcur++];
		Sys.print(name+" : ");
		if (passwd) {
			var s = new StringBuf();
			do switch Sys.getChar(false) {
				case 10, 13: break;
				case c: s.addChar(c);
			}
			while (true);
			Cli.print("");
			return s.toString();
		}
		return Sys.stdin().readLine();
	}

	public function paramOpt() {
		if (args.length > argcur)
			return args[argcur++];
		return null;
	}

	public function readPassword (site, user:String, prompt = "Password"):String {
		var password = Md5.encode(param(prompt,true));
		var attempts = 5;
		while (!site.checkPassword(user, password)) {
			Cli.print('Invalid password for $user');
			if (--attempts == 0)
				throw 'Failed to input correct password';
			password = Md5.encode(param('$prompt ($attempts more attempt${attempts == 1 ? "" : "s"})', true));
		}
		return password;
	}

	public function hasNext () {
		return argcur < args.length;
	}

	public function next () {
		return args[argcur++];
	}

	public function reset () {
		argcur = 0;
	}
}
