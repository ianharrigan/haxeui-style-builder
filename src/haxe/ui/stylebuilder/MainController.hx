package haxe.ui.stylebuilder;

import haxe.ui.toolkit.core.Component;
import haxe.ui.toolkit.core.interfaces.IItemRenderer;
import haxe.ui.toolkit.core.interfaces.InvalidationFlag;
import haxe.ui.toolkit.core.Macros;
import haxe.ui.toolkit.core.PopupManager.PopupButton;
import haxe.ui.toolkit.core.renderers.ComponentItemRenderer;
import haxe.ui.toolkit.core.Toolkit;
import haxe.ui.toolkit.core.XMLController;
import haxe.ui.toolkit.data.IDataSource;
import haxe.ui.toolkit.events.MenuEvent;
import haxe.ui.toolkit.events.UIEvent;
import haxe.ui.toolkit.resources.ResourceManager;
import haxe.ui.toolkit.style.Style;
import haxe.ui.toolkit.style.StyleManager;
import haxe.ui.toolkit.style.StyleParser;
import haxe.ui.toolkit.style.Styles;
import openfl.events.Event;

@:build(haxe.ui.toolkit.core.Macros.buildController("ui/main.xml"))
class MainController extends XMLController {
	private var _styles:Array<Style>;
	
	public function new() {
		applyBaseStyles();
		
		#if cpp
			autoUpdate.selected = true;
			updateUserRule.visible = false;
		#end

		attachEvent("menuFile", MenuEvent.SELECT, function(e:MenuEvent) {
			switch (e.menuItem.id) {
				case "menuImport":
					showImport();
				case "menuExport":
					showExport();
				default:
			}
		});
		
		
		addRule.onClick = function(e) {
			addNewRule();
			applyCss();
		};
		
		autoUpdate.onClick = function(e) {
			if (autoUpdate.selected == true) {
				updateUserRule.visible = false;
			} else {
				updateUserRule.visible = true;
			}
		}
		
		availableRules.onChange = function(e) {
			addNewRule();
			applyCss();
		};
		
		userRules.onChange = function(e) {
			var item:IItemRenderer = userRules.selectedItems[0];
			var itemName = item.data.text;
			var css:String = item.data.data;
			if (css == null) {
				return;
			}
			var arr = css.split(";");
			var propMap:Map<String, String> = new Map<String, String>();
			for (item in arr) {
				if (StringTools.trim(item).length == 0) {
					continue;
				}
				var itemArr = item.split(":");
				var cssProp = StringTools.trim(itemArr[0]);
				var cssValue = StringTools.trim(itemArr[1]);
				propMap.set(cssProp, cssValue);
			}
			
			cssProps.dataSource.removeAll();
			var dataSource:IDataSource = Toolkit.processXmlResource("ui/css-props-datasource.xml");
			var xml:Xml = ResourceManager.instance.getXML("data/rules.xml");
			var propertiesString:String = XPathUtil.getXPathValue(xml, "/rules/rule/name[text() = '" + itemName + "']/../properties/@groups");
			if (propertiesString != null) {
				var propertiesArray:Array<String> = propertiesString.split(",");
				var allowedItems:Map<String, String> = new Map<String, String>();
				for (p in propertiesArray) {
					var list:String = XPathUtil.getXPathValue(xml, "/rules/properties/group[@id = '" + StringTools.trim(p) + "']/text()");
					var arr:Array<String> = list.split(",");
					for (a in arr) {
						allowedItems.set(StringTools.trim(a), StringTools.trim(a));
					}
				}
				
				dataSource.moveFirst();
				var hack = false;
				do {
					if (hack == true) {
						dataSource.moveFirst();
						hack = false;
					}
					var temp:String = dataSource.get().text;
					if (allowedItems.exists(temp) == false) {
						dataSource.remove();
						dataSource.moveFirst();
						hack = true;
					}
				} while (dataSource.moveNext());
			}
			cssProps.dataSource = dataSource;
			
			for (n in 0...cssProps.listSize) {
				var item:ComponentItemRenderer = cast cssProps.getItem(n);
				var value = "";
				if (propMap.exists(item.data.text)) {
					value = propMap.get(item.data.text);
				}
				item.component.text = value;
			}
		};
		
		userRules.onComponentEvent = function(e:UIEvent) {
			var item:IItemRenderer = e.data.itemRenderer;
			var selectedIndex:Int = userRules.getItemIndex(item);
			userRules.dataSource.moveFirst();
			var n = 0;
			do {
				if (n == selectedIndex) {
					userRules.dataSource.remove();
					break;
				}
				n++;
			} while (userRules.dataSource.moveNext());
			applyCss();
		};
		
		updateUserRule.onClick = function(e) {
			updateCss();
		};
		
		cssProps.onComponentEvent = function(e) {
			if (autoUpdate.selected == true) {
				updateCss();
			}
		};
		
		previewTabs.onChange = function(e) {
			refreshPreviewContainer();
		};
		
		populateRules();
	}
	
	private function showExport() {
		var controller:ExportDialogController = new ExportDialogController();
		controller.styles = buildStyles();
		var config:Dynamic = { };
		config.buttons = [PopupButton.CLOSE];
		config.styleName = "export-dialog";
		config.width = 700;
		showCustomPopup(controller.view, "Export", config, function(e) {
			/*
			if (e == PopupButton.CONFIRM) {
				controller.savePrefs();
				showSimplePopup("Your settings have been changed. You must restart (or refresh) the application from the new settings to take effect.");
			}
			*/
		});
	}
	
	private function showImport() {
		var controller:ImportDialogController = new ImportDialogController();
		var config:Dynamic = { };
		config.buttons = [PopupButton.CONFIRM, PopupButton.CANCEL];
		config.styleName = "import-dialog";
		config.width = 700;
		showCustomPopup(controller.view, "Import", config, function(e) {
			if (e == PopupButton.CONFIRM) {
				doImport(controller.importText);
			}
		});
	}
	
	private function doImport(importText:String):Void {
		userRules.dataSource.removeAll();
		var styles:Styles = StyleParser.fromString(importText, true);
		for (rule in styles.rules) {
			var style:Style = styles.getStyle(rule);
			var css = "";
			for (p in style.rawProperties) {
				css += p + ";\n";
			}
			
			var selector:Xml = getRuleFromSelector(rule);
			var item:Dynamic =  { data: css, componentType: "button", componentStyleName: "removeRuleButton" };
			if (selector != null) {
				item.text = XPathUtil.getXPathValue(selector, "name/text()");
			} else { // custom/unrecognised item
				item.text = "Custom";
				item.subtext = rule;
			}
			userRules.dataSource.add(item);
		}
		applyCss();
	}
	
	private function buildStyles():Array<String> {
		var styles:Array<String> = new Array<String>();
		for (n in 0...userRules.listSize) {
			var item:ComponentItemRenderer = cast userRules.getItem(n);
			var css:String = item.data.data;
			if (css == null) {
				css = "";
			}
			var itemName:String = item.data.text;
			var itemSelector:String = getRuleSelector(itemName);
			if (itemSelector == null) {
				itemSelector = item.data.subtext;
			}
			styles.push(itemSelector + "=" + css);
		}
		return styles;
	}
	
	private function updateCss():Void {
		if (userRules.selectedItems.length == 0) {
			showSimplePopup("You must first add or select a rule", "Style Builder");
			return;
		}

		var item:IItemRenderer = userRules.selectedItems[0];
		var css:String = "";
		for (n in 0...cssProps.listSize) {
			var item:ComponentItemRenderer = cast cssProps.getItem(n);
			if (item.component.text != "") {
				css += item.data.text + ": " + item.component.text + ";\n";
			}
		}
		item.data.data = css;
		applyCss();
	}
	
	private function addNewRule():Void {
		var item:String = availableRules.text;
		var ruleSelector:String = getRuleSelector(item);
		addRuleSelector(ruleSelector);
		
	}
	
	private function addRuleSelector(ruleSelector:String):Void {
		var ruleAlias:String = getRuleAlias(ruleSelector);
		if (ruleAlias == null) {
			ruleAlias = ruleSelector;
		}
		var cssData:String = "";
		userRules.dataSource.add( { text: ruleAlias, data: cssData, componentType: "button", componentStyleName: "removeRuleButton" } );
		userRules.selectedIndex = userRules.dataSource.size() - 1;
		userRules.ensureVisible(userRules.getItem(userRules.selectedIndex));
		
	}
	
	private function populateRules():Void {
		var xml:Xml = ResourceManager.instance.getXML("data/rules.xml");
		var a:Array<Xml> = XPathUtil.getXPathNodes(xml, "/rules/rule");
		for (item in a) {
			var name:String = XPathUtil.getXPathValue(item, "name/text()");
			var selector:String = XPathUtil.getXPathValue(item, "selector/text()");
			availableRules.dataSource.add( { text: name } );
		}

		availableRules.dataSource.add( { text: "Custom" } );
	}

	private function applyCss():Void {
		var rulesToRemove:Array<String> = new Array<String>();
		for (r in StyleManager.instance.getRules()) {
			if (StringTools.startsWith(r, ".preview")) {
				rulesToRemove.push(r);
			}
		}
		
		for (r in rulesToRemove) {
			StyleManager.instance.removeStyle(r);
		}
		
		applyBaseStyles();
		
		for (n in 0...userRules.dataSource.size()) {
			var item:IItemRenderer = userRules.getItem(n);
			var selector:String = getRuleSelector(item.data.text);
			if (selector == null) {
				selector = item.data.text;
			}
			var css:String = item.data.data;
			var styleString:String = ".preview " + selector + " { " + css + " }";
			StyleManager.instance.addStyles((StyleParser.fromString(styleString)));
		}
		
		refreshPreviewContainer();
	}
	
	private function refreshPreviewContainer():Void {
		var container:Component = previewTabs.selectedPage;
		if (container.id != "previewContainer") {
			container = container.findChild("previewContainer", true);
		}
		
		if (container != null) {
			container.invalidate(InvalidationFlag.STYLE, true);
		} else {
			trace("Could not find preview container");
		}
	}
	
	private function applyBaseStyles() {
		var baseStyles:Styles = StyleParser.fromString(ResourceManager.instance.getText("styles/minimal/minimal.css"));
		for (rule in baseStyles.rules) {
			var style:Style = baseStyles.getStyle(rule);
			rule = ".preview " + rule;
			StyleManager.instance.addStyle(rule, style);
		}
	}
	
	private function getRuleFromSelector(selector:String):Xml {
		var xml:Xml = ResourceManager.instance.getXML("data/rules.xml");
		var node:Xml = XPathUtil.getXPathNode(xml, "/rules/rule/selector[text() = '" + selector + "']");
		if (node != null) {
			node = node.parent;
		}
		return node;
	}
	
	private function getRuleAlias(selector:String):String {
		var node:Xml = getRuleFromSelector(selector);
		var alias:String = null;
		if (node != null) {
			alias = XPathUtil.getXPathValue(node, "name/text()");
		}
		return alias;
	}
	
	private function getRuleFromAlias(alias:String):Xml {
		var xml:Xml = ResourceManager.instance.getXML("data/rules.xml");
		var node:Xml = XPathUtil.getXPathNode(xml, "/rules/rule/name[text() = '" + alias + "']");
		if (node != null) {
			node = node.parent;
		}
		return node;
	}
	
	private function getRuleSelector(alias:String):String {
		var node:Xml = getRuleFromAlias(alias);
		var selector:String = null;
		if (node != null) {
			selector = XPathUtil.getXPathValue(node, "selector/text()");
		}
		return selector;
	}
}