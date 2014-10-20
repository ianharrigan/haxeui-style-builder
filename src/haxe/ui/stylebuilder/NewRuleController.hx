package haxe.ui.stylebuilder;

import haxe.ui.toolkit.controls.selection.ListSelector;
import haxe.ui.toolkit.core.XMLController;
import haxe.ui.toolkit.resources.ResourceManager;

@:build(haxe.ui.toolkit.core.Macros.buildController("ui/newRulePopup.xml"))
class NewRuleController extends XMLController {
	public function new() {
		//super("ui/newRulePopup.xml");
		
		populateRules();
	}
	
	private function populateRules():Void {
		var xml:Xml = ResourceManager.instance.getXML("data/rules.xml");
		var a:Array<Xml> = XPathUtil.getXPathNodes(xml, "/rules/rule");
		for (item in a) {
			var name:String = XPathUtil.getXPathValue(item, "name/text()");
			var selector:String = XPathUtil.getXPathValue(item, "selector/text()");
			ruleList.dataSource.add( { text: name } );
		}

		ruleList.dataSource.add( { text: "Custom" } );
		
		/*
		var ruleList:ListSelector = getComponentAs("ruleList", ListSelector);
		var xml:Xml = ResourceManager.instance.getXML("data/rules.xml");
		var a:Array<Xml> = XPathUtil.getXPathNodes(xml, "/rules/rule");
		for (item in a) {
			var name:String = XPathUtil.getXPathValue(item, "name/text()");
			var selector:String = XPathUtil.getXPathValue(item, "selector/text()");
			ruleList.dataSource.add( { text: name } );
		}

		ruleList.dataSource.add( { text: "Custom" } );
		*/
	}

	public var selectedItem(get, null):String;
	private function get_selectedItem():String {
		/*
		var ruleList:ListSelector = getComponentAs("ruleList", ListSelector);
		return ruleList.selectedItems[0].text;
		*/
		return null;
	}
}