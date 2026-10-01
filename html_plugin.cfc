component {

	public function init( coldsoup.coldsoup coldsoupObj ) {
		
		variables.jsoupObj=arguments.coldsoupObj;
		variables.bridgeObj = new bridge.bridge_parser(jsoupObj=arguments.coldsoupObj);

		return this;
	}

	public string function process(required struct doc, string path="") localmode=true {
		patternObj = createObject( "java", "java.util.regex.Pattern");

		arguments.doc.html = wrapSuits(arguments.doc.html);

		pattern = patternObj.compile(
		    "<bridge\b([^>]*)>(.*?)</bridge>",
		    patternObj.CASE_INSENSITIVE + patternObj.DOTALL
		);

		tagObjs = pattern.matcher(arguments.doc.html);
		tags = [];

		while (tagObjs.find()){
		    arrayAppend(tags, tagObjs.group());
		}

		for (tag in tags) {
			
			node = variables.jsoupObj.parse(tag);
			hand = node.select("bridge").first();
			handhtml = variables.bridgeObj.bridgeTag(hand, arguments.path);
			handhtml= stripWhiteSpace(handhtml);
			arguments.doc.html = Replace(arguments.doc.html,tag,handhtml);
			
		}

		
		
		return arguments.doc.html;

	}

	/**
     * Wraps card suit symbols with <span class='suit X'> elements.
     * Example: ♠ → <span class='suit s'>♠</span>
     */
    public string function wrapSuits(required string html) {
        return variables.bridgeObj.formatInlineHtml(arguments.html);
    }

    /**
     * remove white space from the start of lines
     */
    public string function stripWhiteSpace(string html) localmode=true {
        
    	
        return Replace(arguments.html,"	","","all");



    }


    /**
     * @hint Parse attributes into a struct from a single tag string
     *
     *  (e.g.  id=xx class='ghhtt'). Attributes can be single quoted, double quote or alpha numeric"
     *  
     */
    public struct function parseTagAttributes(string text) localmode=true {
	    
	    ret = [=];
		
		for (pairs in listToArray(arguments.text," ") ) {
			attrs = listToArray(pairs,"����'""=");
			ret[attrs[1]] = attrs[2];
		}

		return ret;
	}


}