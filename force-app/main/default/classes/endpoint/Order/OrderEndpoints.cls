@RestResource(urlMapping='/order/*')
global with sharing class OrderEndpoints {

    @HttpPost
    global static void createOrderLogSalesforce() {


        RestRequest request  = RestContext.request;
        
        RestResponse response = RestContext.response;

        List<Order> orderList = (List<Order>) JSON.deserialize(request.requestBody.toString(), List<Order>.class);

        List<Order> toUpdate = new List<Order>();
        List<Order> toInsert = new List<Order>();

        for(Order iOrder: orderList){
            if (iOrder.Id == null) toInsert.add(iOrder); else toUpdate.add(iOrder);

        }

    
        if (toInsert.size() > 0) insert toInsert;
        if (toUpdate.size() > 0) update toUpdate;


        Map<String, Object> responseBody = new Map<String, Object>();

        responseBody.put('status', 'success');
        responseBody.put('Order', orderList);

        String jsonResponse = JSON.serializePretty(responseBody);

        ApiLog__c log = new ApiLog__c(Request__c = request.requestBody.toString() , Response__c = jsonResponse, From__c = 'TOTVS', Endpoint__c = 'ORDER');
        Insert log;

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');

        response.responseBody = Blob.valueOf(jsonResponse);
  
    }

    @HttpPut
    global static void putOrderLogSalesforce() {


        RestRequest request  = RestContext.request;
        
        RestResponse response = RestContext.response;

        List<Order> orderList = (List<Order>) JSON.deserialize(request.requestBody.toString(), List<Order>.class);

        List<Order> toUpdate = new List<Order>();

        Set<Id> orderids = new Set<Id>();

        Set<String> orderExternalidsString = new Set<String> ();

        for(Order iOrder : orderList){
            
            if (iOrder.Id != null) orderids.add(iOrder.Id);
            
            if(iOrder.ExternalId__c != null) orderExternalidsString.add(iOrder.ExternalId__c);
        
        }

        List<Order> existingOrder = [
            SELECT Id, ExternalId__c
            FROM Order
            WHERE Id IN :orderids
            OR ExternalId__c IN :orderExternalidsString    
        ];

        for(Order iOrder : existingOrder){

            for(Order iOrder2 : orderList){
                if(iOrder.id == iOrder2.Id || iOrder.ExternalId__c == iOrder2.ExternalId__c){
                    
                    if(iOrder2.id == null) iOrder2.Id = iOrder.Id;

                    toUpdate.add(iOrder2);
                    break;
                }

            }
        }
    
        if (toUpdate.size() > 0) update toUpdate;


        Map<String, Object> responseBody = new Map<String, Object>();

        responseBody.put('status', 'success');
        responseBody.put('Order', orderList);

        String jsonResponse = JSON.serializePretty(responseBody);

        ApiLog__c log = new ApiLog__c(Request__c = request.requestBody.toString() , Response__c = jsonResponse, From__c = 'TOTVS', Endpoint__c = 'ORDER');
        Insert log;

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');

        response.responseBody = Blob.valueOf(jsonResponse);
  
    }

    @HttpDelete
    global static void deleteOrderLogSalesforce() {


        RestRequest request  = RestContext.request;
        
        RestResponse response = RestContext.response;

        List<Order> orderList = (List<Order>) JSON.deserialize(request.requestBody.toString(), List<Order>.class);
    
        if (orderList.size() > 0) delete orderList;


        Map<String, Object> responseBody = new Map<String, Object>();

        responseBody.put('status', 'success');
        responseBody.put('Order', orderList);

        String jsonResponse = JSON.serializePretty(responseBody);

        ApiLog__c log = new ApiLog__c(Request__c = request.requestBody.toString() , Response__c = jsonResponse, From__c = 'TOTVS', Endpoint__c = 'ORDER');
        Insert log;

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');

        response.responseBody = Blob.valueOf(jsonResponse);
  
    }
}