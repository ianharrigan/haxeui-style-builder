package haxe.ui.stylebuilder;

import haxe.macro.Context;

class StyleBuilderMacros {
	macro public static function buildCssPropsDataSource() {
		var exceptions:Array<String> = ["percentWidth", "percentHeight", "autoSizeSet", "target", "autoApply", "apply",
										"addDynamicValue", "hasDynamicValue", "getDynamicValue", "merge", "toString",
										"self", "clone", "addRawProperty", "rawProperties"];
		
		// some other exceptions im not sure if they should be there or not
		exceptions.push("width");
		exceptions.push("height");
		exceptions.push("autoSize");
		
		var t = Context.getType("haxe.ui.toolkit.style.Style");
		var list:Array<String> = new Array<String>();
		switch (t) {
			case TAnonymous(t): {};
			case TMono(t): {};
			case TLazy(t): {};
			case TFun(t, _): {};
			case TDynamic(t): {};
			case TInst(t, _): {
				for (f in t.get().fields.get()) {
					var skip = false;
					if (f.kind.match(FVar(AccNormal,AccNormal))) {
						skip = true;
					}
					if (StringTools.startsWith(f.name, "get_") || StringTools.startsWith(f.name, "set_")) {
						skip = true;
					}
					if (Lambda.indexOf(exceptions, f.name) != -1) {
						skip = true;
					}
					
					if (skip == false) {
						list.push(f.name);
					}
				}
			}
			case TEnum(t, _): {};
			case TType(t, _): {};
			case TAbstract(t, _): {};
		}
		
		var content:String = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<json>\n\t[\n";
		for (n in 0...list.length) {
			var prop:String = list[n];
			var line:String = "\t\t{";
			
			line += "\"text\": \"" + prop + "\"";
			line += ", \"componentType\": \"textinput\"";
			line += ", \"componentValue\": \"\"";
			line += ", \"componentSize\": 100";
			
			line += "}";
			if (n  < list.length - 1) {
				line += ",";
			}
			line += "\n";
			content += line;
		}
		content += "\t]\n</json>\n";
		sys.io.File.saveContent("assets/ui/css-props-datasource.xml", content);
		
		return Context.parseInlineString("function() { }()", Context.currentPos());
	}
}