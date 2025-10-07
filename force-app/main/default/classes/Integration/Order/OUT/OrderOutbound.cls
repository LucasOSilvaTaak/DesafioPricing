global with sharing class OrderOutbound {

    public static OutResponse orderCalloult(List<Id> orderIds){
            List<Order> orderList = [
                SELECT Id, Account.ExternalId__c, ExternalId__c, order.PaymentCondition__r.ExternalId__c, EffectiveDate, 
                    AccountAddress__r.ExternalId__c, FreightType__c, DistributionCenter__r.ExternalId__c, RepresentativeOrderNumber__c, 
                    DeliveryDate__c, Status, Observation__c,
                    (SELECT ExternalId__c, Product2.ExternalId__c, Quantity, UnitPrice, TotvsItem__c, ListPrice 
                        FROM OrderItems
                        WHERE isDeletedExternal__c = false 
                        AND ExternalId__c != null
                    )
                FROM Order
                WHERE Id in :orderIds

            ];

        OutResponse response = sendCallout(orderList);

        return response;

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
        
        RequestResponse requestResponse = ExecuteCallout.executeCallout(endPoint, payload, headersMap);
        
        OutResponse outResponse;

        
        
        
        if(requestResponse.exceptionObject == null || requestResponse.exceptionObject.getMessage() == ''){
            outResponse = new OutResponse(requestResponse);
            
        }
        else {
            outResponse = new OutResponse(requestResponse.exceptionObject.getMessage(), requestResponse);
            
        }
        
        String externalIdList = '';
        
        for (Order iOrder : orderList) {
            if (iOrder.ExternalId__c != null) {
                externalIdList += (String.isBlank(externalIdList) ? '' : ',') + iOrder.ExternalId__c;
            }
        }


        IntegrationLog.createLog('Order', externalIdList, 'Outbound', payload, outResponse.response.response.getBody(), endPoint, !outResponse.success, false, requestResponse.exceptionObject?.getMessage());
        
        return outResponse;

    }

     

}