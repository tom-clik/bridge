component extends="bridge.bridge_parser" {
    public function init() {
        super.init();
        this.requests = [];
        this.responses = {};
        return this;
    }

    public struct function requestHandviewerURL(required string url) {
        this.requests.append(arguments.url);
        if (!this.responses.keyExists(arguments.url)) throw(type="test", message="Unexpected network request: " & arguments.url);
        return this.responses[arguments.url];
    }
}
