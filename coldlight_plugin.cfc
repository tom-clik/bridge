component implements="coldlight.pluginInterface" {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.bridgeObj = new bridge.bridge_parser(jsoupObj=arguments.coldsoupObj);
		
		return this;
	}

	public void function process(required node, required struct document) localmode=true {

		hands = arguments.node.select("bridge");

		for (hand in hands) {
			html = variables.bridgeObj.bridgeTag(hand, arguments.document.basepath);
			hand.html(html).unwrap();
		}

	}

}