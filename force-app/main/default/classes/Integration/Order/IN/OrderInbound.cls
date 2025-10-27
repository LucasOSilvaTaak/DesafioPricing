@RestResource(urlMapping='/orders/*')
global with sharing class OrderInbound {

    global class OrderRequestWrapper {
        public List<Wrappers.OrderWrapper> request;
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
    List<OrderItem> itemsToDelete = new List<OrderItem>();
    List<String> externalIds = new List<String>();
    List<InResponse> orderResponseList = new List<InResponse>();
    List<FilledObjects.FilledObject> filledOrderList = new List<FilledObjects.FilledObject>();
    List<FilledObjects.FilledObject> filledItemList = new List<FilledObjects.FilledObject>();

    String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/orders/*';

    Savepoint savePoint = Database.setSavepoint();
        
    try{

        
        
        filledOrderList = FilledObjectServices.processRequiredsFullValidation(request);        
        
        ordersToUpsert = FilledObjectServices.getAllSobjects(filledOrderList);
        
        system.debug('ordersToUpsert: ' + ordersToUpsert.size());
        
        List<Wrappers.OrderItemWrapper> allItemsWrappers = new List<Wrappers.OrderItemWrapper>();
        
        for (FilledObjects.FilledObject iFilledOrder : filledOrderList) {

            Wrappers.OrderWrapper orderWrapper = (Wrappers.OrderWrapper) iFilledOrder.wrapper;
                
            allItemsWrappers.addAll(orderWrapper.orderItems);

        }
        
        filledItemList = FilledObjectServices.processRequiredsFullValidation(allItemsWrappers);
        
        itensToUpsert = FilledObjectServices.getAllSobjects(filledItemList);
                
        for(OrderItem iOrderItem : [SELECT Id, ExternalId__c, OrderId FROM OrderItem WHERE 
             Order.ExternalId__c IN : WrappersService.getAllExternalIds(request)
        ]) 
            itemsToDelete.add(iOrderItem);     

        
        if(!FilledObjectServices.verifyHasErrors(filledOrderList) && !FilledObjectServices.verifyHasErrors(filledItemList)){
            
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



    for(FilledObjects.FilledObject iFilledOrder : filledOrderList ){
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

    for(FilledObjects.FilledObject iFilledItem : filledItemList ){
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
