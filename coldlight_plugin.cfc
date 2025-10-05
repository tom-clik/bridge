component implements="coldlight.pluginInterface" {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.jsoupObj=arguments.coldsoupObj;
		variables.bridgeObj = new bridge.bridge_parser(jsoupObj=arguments.coldsoupObj);
		
		return this;
	}

	public void function process(required node, required struct document) localmode=true {

		hands = arguments.node.select("bridge");
		count = 1;
		tags = {};

		// first process and store them, we need to replace text in all other nodes before we put them back in.
		for (hand in hands) {
			try {
				html = variables.bridgeObj.bridgeTag(hand, arguments.document.basepath);
			}
			catch (any e) {
				html = "<!-- Failed to parse bridge hand -->";
			}
			tags[count] = html;
			hand.html("").attr("id", "bridgetag-#count#");
			count++;
		}

		wrapSuits(arguments.node);

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
    public void function wrapSuits(string node) localmode=true {
        
    	// Map of suits and their CSS class suffixes
        suits = {
            "♠": "s",
            "♥": "h",
            "♦": "d",
            "♣": "c"
        };

        // Loop through every text node in the document
        for (element in node.select("*")) {
            textNodes = element.textNodes();

            for (textNode in textNodes) {
                text = textNode.getWholeText();
                replaced = text;

                // Replace each suit symbol safely
                for (symbol in suits) {
                    cssClass = suits[symbol];
                    replacement = "<span class='suit " & cssClass & "'>" & symbol & "</span>";
                    replaced = replaced.replace(symbol, replacement);
                }

                // If any change was made, replace the node
                if (!replaced.equals(text)) {
                    // Parse the replaced fragment safely as HTML
                    fragment = variables.jsoupObj.Jsoup.parse(replaced).body().childNodes();
                    for (node in fragment) {
                        textNode.before(node);
                    }
                    textNode.remove();
                }
            }
        }

    }


}