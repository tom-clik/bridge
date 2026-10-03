component implements="coldlight.plugins.pluginInterface" {

	public function init(markdown.flexmark markdownObj, coldsoup.coldsoup coldsoupObj) {
		
		variables.jsoupObj=arguments.coldsoupObj;
		variables.bridgeObj = new bridge.bridge_parser(jsoupObj=arguments.coldsoupObj);
		
		return this;
	}

	/** Capture IDs from a full HTML string or Jsoup Document without mutating it. */
	public array function saveImages(required any document, required array images,
		required string outputFolder, required string baseUrl, required string nodePath,
		struct options={}) localmode=true {
		if (!arrayLen(arguments.images)) return [];
		if (!reFindNoCase("^(https?://|file:/)", arguments.baseUrl))
			throw(type="bridge.images", message="baseUrl must be an absolute HTTP(S) or file URL");
		html = isSimpleValue(arguments.document) ? arguments.document : arguments.document.outerHtml();
		node = variables.jsoupObj.Jsoup.parse(html);
		// This snapshot lives in a temporary directory. Resolve resources at the original location.
		node.select("base").remove();
		node.head().prependElement("base").attr("href", arguments.baseUrl);
		node.outputSettings().charset("UTF-8");
		converter = new coldlight.converters.htmlToPng(arguments.nodePath);
		return converter.convert(node.outerHtml(), arguments.images, arguments.outputFolder, arguments.options);
	}

	/** Build a capture batch; data-image marks tables, while IDs determine filenames. */
	public array function tableImageBatch(required any node, string folder="images") localmode=true {
		batch = [];
		for (table in arguments.node.select("table[data-image]")) {
			id = table.id();
			if (!reFind("^[A-Za-z0-9_-]+$", id))
				throw(type="bridge.images", message="Image tables need a filename-safe ID (letters, digits, underscores or hyphens)", detail=id);
			batch.append({"id":id, "filename":(len(arguments.folder) ? arguments.folder & "/" : "") & "table-" & id & ".png"});
		}
		return batch;
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
