package haxe.ui.stylebuilder;

import haxe.ui.toolkit.core.XMLController;

@:build(haxe.ui.toolkit.core.Macros.buildController("ui/export-dialog.xml"))
class ExportDialogController extends XMLController {
	public var _styles:Array<String>;
	
	public function new() {
	}
	
	private function refreshCSS():Void {
		var css:String = "";

		for (item in _styles) {
			var items:Array<String> = item.split("=");
			var rule = items[0];
			item = items[1];
			
			css += rule + " {\n";
			
			var arr:Array<String> = item.split(";");
			for (a in arr) {
				a = StringTools.trim(a);
				if (a.length == 0) {
					continue;
				}
				css += "\t" + a + ";\n";
			}
			
			css += "}\n\n";
		}
		
		cssCode.text = css;
	}
	
	public var styles(get, set):Array<String>;
	private function get_styles():Array<String> {
		return _styles;
	}
	private function set_styles(value:Array<String>):Array<String> {
		_styles = value;
		refreshCSS();
		return value;
	}
}