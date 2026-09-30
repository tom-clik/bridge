// Expose the parser helpers without loading the visual demo's stylesheets.
component extends="bridge.bridge_parser" {
    public function parsePBN(required string text) {
        return super.parsePBN(argumentCollection=arguments);
    }

    public function displayAuction(required struct pbndata, required struct styleAtts) {
        super.parseStyleShortcuts(arguments.styleAtts);
        return super.displayAuction(argumentCollection=arguments);
    }
}
