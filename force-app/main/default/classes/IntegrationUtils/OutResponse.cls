public with sharing class OutResponse {
    public RequestResponse response;
    public Boolean success;
    public String errorMessage;

    public OutResponse(RequestResponse requestResponse){
        this.success = true;
        this.errorMessage = '';
        this.response = requestResponse;
    }

    public OutResponse(String errorMessage){
        this.success = false;
        this.errorMessage = errorMessage;
        this.response = null;
    }

    public OutResponse(String errorMessage, RequestResponse requestResponse){
        this.success = false;
        this.errorMessage = errorMessage;
        this.response = requestResponse;
    }
}