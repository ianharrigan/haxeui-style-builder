package haxe.ui.stylebuilder;

import haxe.ui.toolkit.core.XMLController;

@:build(haxe.ui.toolkit.core.Macros.buildController("ui/import-dialog.xml"))
class ImportDialogController extends XMLController {
	public function new() {
		
	}
	
	public var importText(get, null):String;
	private function get_importText():String {
		return cssCode.text;
	}
}