global with sharing class OrderOutbound {

    @InvocableMethod
    public static List<String> orderCalloult(List<Id> orderIds){
            List<Order> orderList = [
                SELECT Id, Account.ExternalId__c, ExternalId__c, order.PaymentCondition__r.ExternalId__c, EffectiveDate, 
                    AccountAddress__r.ExternalId__c, FreightType__c, DistributionCenter__r.ExternalId__c, 
                    DeliveryDate__c, Status, Observation__c, OrderNumber,
                    (
                        SELECT ExternalId__c, Product2.ExternalId__c, Quantity, UnitPrice, TotvsItem__c, ListPrice , OrderId, OrderItemNumber
                        FROM OrderItems
                        WHERE isDeletedExternal__c = false 
                    )
                FROM Order
                WHERE Id in :orderIds

            ];

        OutResponse response = sendCallout(orderList);

        List<String> responseList = new List<String>();
        responseList.add(response.response.response.getBody());

        return responseList;

    }

    public static OutResponse sendCallout(List<Order> orderList){
        
        List<Wrappers.OrderWrapper> orderWrapperList = new List<Wrappers.OrderWrapper>();

        for(Order iOrder : orderList){
           
            Wrappers.OrderWrapper tempOrderWrapper = new Wrappers.OrderWrapper();
           
            tempOrderWrapper.serialize(iOrder);

            orderWrapperList.add(tempOrderWrapper);
        }

        Map<String, List<Wrappers.OrderWrapper>> requestMap = new Map<String, List<Wrappers.OrderWrapper>>();


        requestMap.put('request', orderWrapperList);

        

        String payload = JSON.serialize(requestMap);
        
        String endPoint = 'callout:ApiCredential/services/apexrest/upsertOrder/';

        System.debug(payload);
        System.debug(endPoint);

        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        
        RequestResponse requestResponse = ExecuteCallout.executeCalloutPost(endPoint, payload, headersMap);
        
        OutResponse outResponse;
        
        
        if(requestResponse.exceptionObject == null || requestResponse.exceptionObject.getMessage() == ''){
            outResponse = new OutResponse(requestResponse);
            
            for(Order iOrder : orderList){
                iOrder.Status = 'Integrated';
            }
            
        }
        else {
            outResponse = new OutResponse(requestResponse.exceptionObject.getMessage(), requestResponse);
            
            for(Order iOrder : orderList){
                iOrder.Status = 'Integration Error';
            }
            
        }
        
        update orderList;
        
        String externalIdList = '';
        
        for (Order iOrder : orderList) {
            if (iOrder.ExternalId__c != null) {
                externalIdList += (String.isBlank(externalIdList) ? '' : ',') + iOrder.ExternalId__c;
            }
        }
 
        
       IntegrationLogsBuilder.LogBuilder logBuilder = new IntegrationLogsBuilder.LogBuilder();
        logBuilder.setEndpoint(endpoint)
            .setPayloadIN(payload)
            .setPayloadOUT(outResponse.response.response.getBody())
            .setExternalIdList(externalIdList)
            .setHasAnyErrors(!outResponse.success)
            .setIntegrationName('Outbound', 'Order')
            .setErrorMessage(requestResponse.exceptionObject?.getMessage())
            .insertBuild();

        return outResponse;
            
        
    }
}
