component extends="bridge.bridge_parser" {

	public function init() {
		this.flexmark = new markdown.testing.flexmarkTestObj();
		super.init(jsoupObj = this.flexmark.coldsoupObj);
		local.dir = getCanonicalPath(getDirectoryFromPath( getCurrentTemplatePath() )) ;
		this.styles = "<style>" & fileRead( local.dir  & "../../clikpage/_assets/css/reset.css");
		this.styles &= fileRead( local.dir  & "../assets/css/bridge_styles.css") & "</style>";
		

		this.loggerObj = new logger.logger(debug=1);
		this.testhand = fileRead( local.dir  & "hands/test_hand2.pbn");
		return this;
	}

	public array function parseAuction(auctionStr) {
		return super.parseAuction(argumentCollection = arguments);
	}


	public function parseStyleShortcuts(struct styles={}) {
		return super.parseStyleShortcuts(argumentCollection = arguments);
	}

	public function parseDealData( required dealStr ) {
		return super.parseDealData(argumentCollection = arguments);
	}

	public function checkHandType(required text, required struct styleAtts) {
		return super.checkHandType(argumentCollection = arguments);
	}

	public function parseHand(required text) {
		return super.parseHand(argumentCollection = arguments);
	}

	public function displayHand(required struct hand) {
		return super.displayHand(argumentCollection = arguments);
	}

	public function parseSuitCombo(required string deal) {
		return super.parseSuitCombo(argumentCollection = arguments);
	}

	public function displaySuitCombo(required struct suit) {
		return super.displaySuitCombo(argumentCollection = arguments);
	}

	public function parsePBN(required string text) {
		return super.parsePBN(argumentCollection = arguments);
	}

	public function displayDeal(required struct pbndata, required struct styleAtts) {
		parseStyleShortcuts(arguments.styleAtts);
		return super.displayDeal(argumentCollection = arguments);
	}

	public function displayAuction(required struct pbndata, required struct styleAtts) {
		parseStyleShortcuts(arguments.styleAtts);
		return super.displayAuction(argumentCollection = arguments);
	}

	

}