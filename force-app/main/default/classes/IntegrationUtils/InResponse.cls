global with sharing virtual class Response{

    public String salesforceId;
    public String externalCode;
    public String sobjectType;
    public Boolean hasError;
    public String errorMessage;

    public void success(String salesforceId, String externalId, String sobjectType){
        this.salesforceId	= salesforceId;
        this.externalCode	= externalId;
        this.sobjectType	= sobjectType;
        this.hasError		= false;
    }

    public void error(String externalId, String errorMessage, String sobjectType){
        this.externalCode	= externalId;
        this.sobjectType	= sobjectType;
        this.hasError		= true;
        this.errorMessage	= errorMessage;
    }

    public void error(String salesforceId, String externalId, String errorMessage, String sobjectType){
        this.salesforceId	= salesforceId;
        this.externalCode	= externalId;
        this.sobjectType	= sobjectType;
        this.hasError		= true;
        this.errorMessage	= errorMessage;
    }
}