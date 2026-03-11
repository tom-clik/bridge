component {

	public function init( coldsoup.coldsoup coldsoupObj ) {
		
		variables.jsoupObj=arguments.coldsoupObj;
		variables.bridgeObj = new bridge.bridge_parser(jsoupObj=arguments.coldsoupObj);

		return this;
	}

	public string function process(required string html, string path="") localmode=true {
		patternObj = createObject( "java", "java.util.regex.Pattern");

		arguments.html = wrapSuits(arguments.html);

		pattern = patternObj.compile(
		    "<bridge\b([^>]*)>(.*?)</bridge>",
		    patternObj.CASE_INSENSITIVE + patternObj.DOTALL
		);

		tagObjs = pattern.matcher(arguments.html);
		tags = [];

		while (tagObjs.find()){
		    arrayAppend(tags, tagObjs.group());
		}

		for (tag in tags) {
			
			node = variables.jsoupObj.parse(tag);
			hand = node.select("bridge").first();
			handhtml = variables.bridgeObj.bridgeTag(hand, arguments.path);
			handhtml= stripWhiteSpace(handhtml);
			arguments.html = Replace(arguments.html,tag,handhtml);
			
		}

		
		
		return arguments.html;

	}

	/**
     * Wraps card suit symbols with <span class='suit X'> elements.
     * Example: ♠ → <span class='suit s'>♠</span>
     */
    public string function wrapSuits(string html) localmode=true {
        
    	// Map of suits and their CSS class suffixes
        suits = {
            "♠": "s",
            "♥": "h",
            "♦": "d",
            "♣": "c"
        };

        loop collection=suits key="symbol" value="cssClass" {
        	arguments.html = replace(arguments.html, symbol, "<span class='suit " & cssClass & "'>" & symbol & "</span>","all");
        }
        return html;



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