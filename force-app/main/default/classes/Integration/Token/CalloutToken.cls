public with sharing class CalloutToken {
    
    public static void createToken() {

        CalloutIntegrationUtils.CalloutResponse calloutResponse = getToken();

        if(calloutResponse.success) {
            ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'Token__mdt.Default'; 
            customMetadata.label = 'Default Token';

            Metadata.CustomMetadataValue tokenValue = new Metadata.CustomMetadataValue();
            tokenValue.field = 'Value__c'; 
            tokenValue.value = resp.responses.access_token;

            customMetadata.values.add(tokenValue);

            Metadata.DeployContainer container = new Metadata.DeployContainer();
            container.addMetadata(customMetadata);

            Id jobId = Metadata.Operations.enqueueDeployment(container, new SimpleDeployCallback());
        }
    }

    public static String retrieveToken() {
        createToken();
        
        Token__mdt tokenRecord = [
            SELECT Value__c
            FROM Token__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return tokenRecord.Value__c;
    
    }
    
    public static CalloutIntegrationUtils.CalloutResponse getToken() {

        
        String endpoint = tokenUrl();

        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');

        CalloutIntegrationUtils.RequestResponseObject responseObject = CalloutIntegrationUtils.executeCallout(endpoint, '', headersMap);
        HttpResponse response = responseObject.response;

        ResponseParametersWrapper responses = (ResponseParametersWrapper) JSON.deserialize(response.getBody(), ResponseParametersWrapper.class);
        
        return new CalloutIntegrationUtils.CalloutResponse(new ResponseParameters(responses));
    }

    public class ResponseParameters implements CalloutIntegrationUtils.CalloutResponseParsedData {
        public ResponseParametersWrapper responses;
        public ResponseParameters(ResponseParametersWrapper responses) {
            this.responses = responses;
        }
    }

    public class ResponseParametersWrapper {
        public String access_token;
        public String signature;
        public String scope;
        public String instance_url;
        public String id;
        public String token_type;
        public String issued_at;
        public String api_instance_url;
    }

    public class SimpleDeployCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        }
    }

    public static string tokenUrl(){
        Secrets__mdt secret = [
            SELECT ClienteId__c, ClientSecret__c, GrantType__c, Password__c, Username__c, Url__c
            FROM 
            Secrets__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];

        return secret.Url__c + '/services/oauth2/token?grant_type=' + secret.GrantType__c + '&client_id='
            + secret.ClienteId__c + '&client_secret=' + secret.ClientSecret__c + '&username=' + secret.Username__c + '&password=' + secret.Password__c;
    }
}
