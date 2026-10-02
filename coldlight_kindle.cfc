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

		verticalHandsToTables( section = arguments.section );
		
	}

	public void function verticalHandsToTables(
	    required struct section
	   ) localmode=true {
	    
	    for (hand in arguments.section.node.select("div.bridge.vertical > span.bridgehand")) {
	        // Keep the children collection so moving nodes does not change the indexes.
            cells = hand.children();

	        // Validate the suit/cards pairs before changing the document.
	        if (cells.size() != 8) {
	            throw(message="Expected four suit/cards pairs.", type="bridge");
	        }

	        for (i = 0; i < 8; i += 2) {
	            if (
	                !cells.get(i).is("span.suit") ||
	                !cells.get(i + 1).is("span.cards")
	            ) {
	                throw(message="Expected alternating suit and cards spans.", type="bridge");
	            }
	        }

	        table = arguments.section.node.createElement("table");

	        // Preserve the hand's classes and any other attributes.
	        table.attributes().addAll(hand.attributes());
	        tbody = table.appendElement("tbody");

	        for (i = 0; i < 8; i += 2) {
	            row = tbody.appendElement("tr");
	            row.appendElement("td").appendChild(cells.get(i));
	            row.appendElement("td").appendChild(cells.get(i + 1));
	        }

	        hand.replaceWith(table);
	    }

	}

	
    
}
