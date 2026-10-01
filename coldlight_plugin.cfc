component implements="coldlight.plugins.pluginInterface" {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.jsoupObj=arguments.coldsoupObj;
		variables.bridgeObj = new bridge.bridge_parser(jsoupObj=arguments.coldsoupObj);
		
		return this;
	}

	public string function preProcess(required string text) localmode=true {

		/**
		 * Process the whole text string before processings
		 *
		 * arguments.text = Replace(arguments.text,"♠","&spade;","all");
		 * 
		 */
		return arguments.text;
		
	}

	public void function process(required struct section, required struct document) localmode=true {

		hands = arguments.section.node.select("bridge");
		count = 1;
		tags = {};

		// first process and store them, we need to replace text in all other nodes before we put them back in.
		for (hand in hands) {
			try {
				html = variables.bridgeObj.bridgeTag(hand, arguments.document.basepath);
			}
			catch (any e) {
				local.extendedinfo = {"error"=e,"hand"=hand};
				throw(
					extendedinfo = SerializeJSON(local.extendedinfo),
					message      = "Failed to parse bridge hand"
				);
			}
			tags[count] = html;
			hand.html("").attr("id", "bridgetag-#count#");
			count++;
		}

		variables.bridgeObj.formatInlineAuctions(arguments.section.node);
		wrapSuits(arguments.section.node);

		// now put them back
		for (hand in hands) {
			id = ListLast(hand.attr("id"), "-");
			hand.html(tags[id]).unwrap();
		}
		

	}

	/**
     * Wraps card suit symbols with <span class='suit X'> elements.
     * Example: ♠ → <span class='suit s'>♠</span>
     */
    public void function wrapSuits(required node) {
        variables.bridgeObj.wrapSuitSymbols(arguments.node);
    }


}
