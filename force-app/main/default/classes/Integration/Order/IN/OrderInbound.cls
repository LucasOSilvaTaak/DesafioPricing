@RestResource(urlMapping='/orders/*')
global with sharing class OrderInbound {

    global class OrderRequestWrapper {
        public List<Wrappers.OrderWrapper> request;
    }

    private static List<FilledObjects.FilledOrder> fillOrder(List<Wrappers.OrderWrapper> request) {
        
        List <FilledObjects.FilledObject> filledList = FilledObjectHelper.verifyRequiredFields(request);

        List<FilledObjects.FilledOrder> filledOrdersList = new List<FilledObjects.FilledOrder>();

        for(FilledObjects.FilledObject iFilledObject : filledList){
           
            filledOrdersList.add( (FilledObjects.FilledOrder) iFilledObject);
            
        }

        Wrappers.OrderWrapper tempOrder = new Wrappers.OrderWrapper();

        for (String key : tempOrder.getRequiredLookups().keySet()) {

            String field = tempOrder.getRequiredLookups().get(key);

            Set<String> externalIds = VerifyFields.getAllExternalIds(field);

            for (FilledObjects.FilledOrder iFilledOrder : filledOrdersList) {

                Map<String, Object> wrapperMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(iFilledOrder.wrapper));

                Object lookupValue = wrapperMap.get(key);

                if (!VerifyFields.verifyLookupFields(externalIds, String.valueOf(lookupValue))) {

                    iFilledOrder.hasError = true;

                    iFilledOrder.errorMessage += ' Invalid lookup field on order with order code "' +
                        iFilledOrder.wrapper.getExternalId() + '" : ' + field + '. ';
                }
            }
        }

        return filledOrdersList;

    }

    private static List<FilledObjects.FilledItem> fillOrderItem(List<Wrappers.OrderWrapper> orders) {

        System.debug('orders size: ' + orders.size());
        
        List<Wrappers.OrderItemWrapper> allItemWrapper = new List<Wrappers.OrderItemWrapper>();
        
        for(Wrappers.OrderWrapper iOrder : orders){
            
            if (iOrder.orderItems == null) continue;
            
            allItemWrapper.addAll(iOrder.orderItems);
            
        }
        
        List<FilledObjects.FilledObject> FilledObjectsList = FilledObjectHelper.verifyRequiredFields(allItemWrapper);
        
        List<FilledObjects.FilledItem> filledItemList = new List<FilledObjects.FilledItem>();

        for (FilledObjects.FilledObject iFilledObject : FilledObjectsList) {

            filledItemList.add( (FilledObjects.FilledItem) iFilledObject);
            
        }

        Wrappers.OrderItemWrapper tempOrderItem = new Wrappers.OrderItemWrapper();
        
        for (String key : tempOrderItem.getRequiredLookups().keySet()) {

            String field = tempOrderItem.getRequiredLookups().get(key);

            Set<String> externalIds = VerifyFields.getAllExternalIds(field);

            for (FilledObjects.FilledItem iFilledItem : filledItemList) {

                Map<String, Object> wrapperMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(iFilledItem.wrapper));

                Object lookupValue = wrapperMap.get(key);

                if (!VerifyFields.verifyLookupFields(externalIds, String.valueOf(lookupValue))) {

                    iFilledItem.hasError = true;

                    iFilledItem.errorMessage += ' Invalid lookup field on Order Item with order code "' +
                        iFilledItem.wrapper.getExternalId() + '" : ' + field + '. ';
                }
            }
        }


        return filledItemList;
    }

    private static Set<Id> getOrderIds(List<Order> ordersToUpsert){

        Set<Id> orderIds = new Set<Id>();

        for(Order iOrder : ordersToUpsert){
                
            orderIds.add(iOrder.Id);  
            
        }

        return orderIds;
    }

    private static Set<String> getItensExternalIds(List<Wrappers.OrderWrapper> ordersToUpsert){

        Set<String> orderExternalIds = new Set<String>();

        for(Wrappers.OrderWrapper iOrder : ordersToUpsert){
            
            if(iOrder.orderItems == null) continue;
           
            for(Wrappers.OrderItemWrapper iItemWrapper : iOrder.orderItems){
          
                orderExternalIds.add(iItemWrapper.itemCode);
           
            }
        
        }

        return orderExternalIds;
    }

    private static List<OrderItem> getExistingItems(List<Order> ordersToUpsert, List<Wrappers.OrderWrapper> request){

        List<OrderItem> existingItems = new List<OrderItem>();

        Set<Id> foundOrders = getOrderIds(ordersToUpsert);

        Set<String> externalIds = getItensExternalIds(request);

        for(OrderItem item : [
            SELECT Id, ExternalId__c, OrderId
            FROM OrderItem
            WHERE ExternalId__c IN :externalIds 

        ]) {
            existingItems.add(item);
        }

        return existingItems;
    }

@HttpPost
global static List<InResponse> createOrder() {

    RestRequest req = RestContext.request;
    
    OrderRequestWrapper body;

    try {
       
        body = (OrderRequestWrapper) JSON.deserialize(req.requestBody.toString(),
            OrderRequestWrapper.class);
        
    } 
    catch (Exception e) {
       
        InResponse errorResponse = new InResponse();
        errorResponse.error(null, 'Erro no formato do JSON recebido: ' + e.getMessage(), 'Order');
    
        return new List<InResponse>{ errorResponse };
    
    }

    List<Wrappers.OrderWrapper> request = body.request;

    if (request == null || request.isEmpty()) {
        InResponse errorResponse = new InResponse();
        errorResponse.error(null, 'No order found.', 'Order');
    
        return new List<InResponse>{ errorResponse };
    }

    Boolean hasError = false;
    Boolean hasDeleted = false;
    String errorMessage = '';

    List<Order> ordersToUpsert = new List<Order>();
    List<OrderItem> itensToUpsert = new List<OrderItem>();
    List<String> externalIds = new List<String>();
    List<InResponse> orderResponseList = new List<InResponse>();
    List<FilledObjects.FilledOrder> filledOrderList = new List<FilledObjects.FilledOrder>();
    List<FilledObjects.FilledItem> filledItemList = new List<FilledObjects.FilledItem>();

    String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/orders/*';

    Savepoint savePoint = Database.setSavepoint();
        
    try{

        filledOrderList = fillOrder(request);            
        
        for (FilledObjects.FilledOrder iFilledOrder : filledOrderList) {
            
            if (!iFilledOrder.hasError) {

                ordersToUpsert.add((Order) iFilledOrder.record);

            }

        }
        
        filledItemList = fillOrderItem(request);
        
        for (FilledObjects.FilledItem iFilledItem : filledItemList) {
            
            if (!iFilledItem.hasError) {
                
                itensToUpsert.add((OrderItem) iFilledItem.record);
                
            }
            
        }
        
        List<OrderItem> itemsToDelete = getExistingItems(ordersToUpsert, request);
        
        if(!FilledObjectHelper.verifyHasErrors(filledOrderList) && !FilledObjectHelper.verifyHasErrors(filledItemList)){
            
            if (!ordersToUpsert.isEmpty()) Database.upsert(ordersToUpsert, Order.ExternalId__c, true);
        
            if (!itemsToDelete.isEmpty()) Database.delete(itemsToDelete, true);
            
            if (!itensToUpsert.isEmpty()) Database.upsert(itensToUpsert, OrderItem.ExternalId__c, true);

            for(Order iOrder : ordersToUpsert){
                OrderResponse tempOrderResponse = new OrderResponse();
                tempOrderResponse.success(iOrder.Id, iOrder.ExternalId__c, iOrder.getSObjectType().getDescribe().getName());

                iOrder.Status = 'Integrated';
                                
            }


            for(OrderItem iOrderItem : itensToUpsert){
                orderResponse tempItemResponse = new orderResponse();
                tempItemResponse.success(
                    iOrderItem.Id, 
                    iOrderItem.ExternalId__c,
                    iOrderItem.getSObjectType().getDescribe().getName()
                );

            }

            update ordersToUpsert;
        }
        
        else hasError = true;
        
        
    } 
    catch (Exception e){
        
        hasError = true;
        errorMessage = 'A error has happend: ' + e.getMessage();
    
        Database.rollback(savePoint);
        
    }

    String orderExternalIds = '';

    for( Wrappers.OrderWrapper iOrder : request ){

        if(iOrder.orderCode == null || iOrder.orderCode == '') continue;
        externalIds.add(iOrder.orderCode);

    }



    for(FilledObjects.FilledOrder iFilledOrder : filledOrderList ){
        OrderResponse tempResponse = new OrderResponse();

        if(hasError){
            tempResponse.error(
                (String) iFilledOrder.record.get('ExternalId__c'),
                String.isNotBlank(errorMessage) &&  String.isBlank(iFilledOrder.errorMessage) ? 
                    errorMessage : iFilledOrder.errorMessage,
                'Order'

            );
            orderResponseList.add(tempResponse);
        }
        else{
            
            tempResponse.success(
                iFilledOrder.record.Id,
                (String) iFilledOrder.record.get('ExternalId__c'),
                'Order'
            );

            orderResponseList.add((InResponse)tempResponse);
        
        }
    }

    for(FilledObjects.FilledItem iFilledItem : filledItemList ){
        ItemResponse tempResponse = new ItemResponse();

        if(hasError){
            
            tempResponse.error(
                iFilledItem.externalId,
                String.isNotBlank(errorMessage) &&  String.isBlank(iFilledItem.errorMessage) ?
                    errorMessage :  iFilledItem.errorMessage,
                'Order Item'
            );
            orderResponseList.add((InResponse) tempResponse);
        
        }
        else{
            
            tempResponse.success(
                iFilledItem.record.Id,
                iFilledItem.externalId,
                'Order Item'
            );

            orderResponseList.add(tempResponse);
        
        }
    }
    
    
    orderExternalIds = String.join(externalIds, ',');

    RestContext.response.statusCode = hasError ? 400 : 200;

    IntegrationLogsBuilder.LogBuilder logBuilder = new IntegrationLogsBuilder.LogBuilder();
    logBuilder.setEndpoint(endpoint)
        .setPayloadIN(JSON.serialize(request))
        .setPayloadOUT(JSON.serialize(orderResponseList))
        .setExternalIdList(orderExternalIds)
        .setHasAnyErrors(hasError)
        .setIntegrationName('Inbound', 'Order')
        .setErrorMessage(errorMessage)
        .setHasDeleted(hasDeleted)
        .insertBuild();

        
    return orderResponseList;
}

    global class OrderResponse extends InResponse{
        //List<itemResponse> itens = new List<itemResponse>();
    }

    global class ItemResponse extends InResponse{}
}
