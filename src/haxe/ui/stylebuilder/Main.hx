package haxe.ui.stylebuilder;

import haxe.ui.toolkit.core.Macros;
import haxe.ui.toolkit.core.Toolkit;
import haxe.ui.toolkit.core.Root;
import haxe.ui.toolkit.style.StyleManager;
import haxe.ui.toolkit.themes.GradientTheme;

class Main {
	public static function main() {
		StyleBuilderMacros.buildCssPropsDataSource();
		//StyleManager.instance.useCache = false;
		Toolkit.theme = new GradientTheme();
		Toolkit.init();
		//Macros.addStyleSheet("assets/data/bootstrap.css");
		Toolkit.openFullscreen(function(root:Root) {
			root.addChild(new MainController().view);
		});
	}
}
