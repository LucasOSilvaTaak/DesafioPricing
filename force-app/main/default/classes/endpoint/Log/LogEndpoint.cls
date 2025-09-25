
@RestResource(urlMapping='/Log/*')
global with sharing class LogEndpoint {


    @httpGet
    global static void getLastLog(){
        
        RestRequest request = RestContext.request;

        RestResponse response = RestContext.response;

        ApiLog__c log = [   
            SELECT Id, Request__c, Response__c, Endpoint__c, From__c, CreatedDate
            FROM  ApiLog__c
            WHERE Endpoint__c = 'Order'
            ORDER BY CreatedDate DESC
            LIMIT 1    
        ];

        
        Map<String, Object> responseBody = new Map<String, Object>();

        responseBody.put('Id', log.Id);
        responseBody.put('Request', log.Request__c);
        responseBody.put('Response', log.Response__c);
        responseBody.put('Endpoint', log.Endpoint__c);
        responseBody.put('From', log.From__c);
        responseBody.put('status', 'success');

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');

        response.responseBody = Blob.valueOf(JSON.serializePretty(responseBody));


        

    }

}