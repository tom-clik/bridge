component extends="bridge.bridge_parser" {

	public function init() {
		this.flexmark = new markdown.testing.flexmarkTestObj();
		super.init(jsoupObj = this.flexmark.coldsoupObj);
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
}