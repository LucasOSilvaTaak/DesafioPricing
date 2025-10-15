@RestResource(urlMapping='/orders/*')
global with sharing class OrderInbound {

    global class OrderRequestWrapper {
        public List<Wrappers.OrderWrapper> request;
    }

    private class FilledItem {
        public OrderItem items;
        public String externalId;
        public Boolean hasError = false;
        public String errorMessage = '';
    }

    private class FilledOrder {
        public Order order;
        public Wrappers.OrderWrapper wrapper;
        public Boolean hasError;
        public String externalId;
        public String errorMessage;

        public FilledOrder(){
            hasError = false;
            errorMessage = '';
        }
    }

    private static List<FilledOrder> fillOrder(List<Wrappers.OrderWrapper> request) {
        
        List<FilledOrder> filledOrdersList = new List<FilledOrder>();

        for (Wrappers.OrderWrapper iOrder : request) {
                
            FilledOrder filledOrder = new FilledOrder();

            Order deserializedOrder = iOrder.deserialize();
            
            Set<String> allFields = iOrder.getRequiredFields();

            Set<String> missingFields = VerifyRequiredFields.verifyRequiredFields(deserializedOrder, allFields);

            missingFields.addAll(iOrder.VerifyRequiredLookups());


            if(!missingFields.isEmpty()){

                filledOrder.hasError = true;
                filledOrder.errorMessage = 'Missing required fields: ' + String.join(new List<String>(missingFields), ', ');
            
            }

            filledOrder.wrapper = iOrder;
            filledOrder.order = deserializedOrder;
            filledOrder.externalId = iOrder.orderCode;

            filledOrdersList.add(filledOrder);
            
        }

        return filledOrdersList;

    }

    private static List<FilledItem> fillOrderItem(List<Wrappers.OrderWrapper> orders) {

        
        List<FilledItem> filledItemList = new List<FilledItem>();


        for(Wrappers.OrderWrapper iOrder : orders){
            
            if (iOrder.orderItems == null) continue;

            for(Wrappers.OrderItemWrapper iOrderItem : iOrder.orderItems){
                
                FilledItem filledItem = new FilledItem();
                                
                iOrderItem.orderCode = iOrder.orderCode;

                OrderItem desirializedItem = iOrderItem.deserialize();

                Set<String> allFields = iOrderItem.getRequiredFields();

                Set<String> missingFields = VerifyRequiredFields.verifyRequiredFields(desirializedItem, allFields);

                missingFields.addAll(iOrderItem.VerifyRequiredLookups());

                if(!missingFields.isEmpty()){

                    filledItem.hasError = true;
                    filledItem.errorMessage = 'Missing required fields: ' + String.join(new List<String>(missingFields), ', ');

                }
                
                filledItem.items = desirializedItem;
        
                filledItem.externalId = iOrderItem.itemCode;

                
                filledItemList.add(filledItem);
                

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
            WHERE (OrderId NOT IN :foundOrders
            AND ExternalId__c IN :externalIds ) 
            OR (ListPrice != null
            AND ExternalId__c IN :externalIds )
            OR (OrderId IN :foundOrders
            AND ExternalId__c NOT IN :externalIds )
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
        body = (OrderRequestWrapper) JSON.deserialize(
            req.requestBody.toString(),
            OrderRequestWrapper.class
        );
        
    } catch (Exception e) {
        InResponse errorResponse = new InResponse();
        errorResponse.error(null, 'Erro no formato do JSON recebido: ' + e.getMessage(), 'Order');
        return new List<InResponse>{ errorResponse };
    }

    if (body == null || body.request == null || body.request.isEmpty()) {
        InResponse errorResponse = new InResponse();
        errorResponse.error(null, 'Campo "request" ausente ou vazio no JSON', 'Order');
        return new List<InResponse>{ errorResponse };
    }

    List<Wrappers.OrderWrapper> request = body.request;

        Boolean hasError = false;
        Boolean hasDeleted = false;
        String errorMessage = '';

        List<Order> ordersToUpsert = new List<Order>();
        List<OrderItem> itensToUpsert = new List<OrderItem>();
        List<String> externalIds = new List<String>();
        List<InResponse> orderResponseList = new List<InResponse>();
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/orders/*';

        List<FilledOrder> filledOrderList = new List<FilledOrder>();
        List<FilledItem> filledItemList = new List<FilledItem>();

        
        try{


            filledOrderList = fillOrder(request);            
            
            List<Wrappers.OrderWrapper> passedRequest = new List<Wrappers.OrderWrapper>();

            for (FilledOrder iFilledOrder : filledOrderList) {
                if (!iFilledOrder.hasError) {

                    passedRequest.add(iFilledOrder.wrapper);
                    ordersToUpsert.add(iFilledOrder.order);

                }

            }
            
            if (!ordersToUpsert.isEmpty()) Database.upsert(ordersToUpsert, Order.ExternalId__c, true);


            //Preenche os itens
            filledItemList = fillOrderItem(passedRequest);

            for (FilledItem iFilledItem : filledItemList) {

                if (!iFilledItem.hasError) {

                    itensToUpsert.add(iFilledItem.items);

                }

            }
                        
            List<OrderItem> toDelete = getExistingItems(ordersToUpsert, passedRequest);

            if (!toDelete.isEmpty()) Database.delete(toDelete, true);
            
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
        catch (Exception e){
           
            hasError = true;
            errorMessage = 'A error has happend: ' + e.getMessage();
            OrderResponse tempResponse = new OrderResponse();
            tempResponse.error(null, errorMessage, 'Order');
            orderResponseList.add(tempResponse);
        
        }

        String orderExternalIds = '';
        if (!hasError){
            for( Wrappers.OrderWrapper iOrder : request ){

                if(iOrder.orderCode == null || iOrder.orderCode == '') continue;
                externalIds.add(iOrder.orderCode);
            }

            for(FilledOrder iFilledOrder : filledOrderList ){
                OrderResponse tempResponse = new OrderResponse();

                if(iFilledOrder.hasError){
                    tempResponse.error(
                        iFilledOrder.order.ExternalId__c,
                        iFilledOrder.errorMessage,
                        'Order'
                    );
                    orderResponseList.add(tempResponse);
                }
                else{
                    
                    tempResponse.success(
                        iFilledOrder.order.Id,
                        iFilledOrder.order.ExternalId__c,
                        'Order'
                    );

                    orderResponseList.add((InResponse)tempResponse);
                
                }
            }

            for(FilledItem iFilledOrder : filledItemList ){
                ItemResponse tempResponse = new ItemResponse();

                if(iFilledOrder.hasError){
                    tempResponse.error(
                        iFilledOrder.items.ExternalId__c,
                        iFilledOrder.externalId,
                        iFilledOrder.errorMessage,
                        'Order Item'
                    );
                    orderResponseList.add((InResponse) tempResponse);
                }
                else{
                    
                    tempResponse.success(
                        iFilledOrder.items.Id,
                        iFilledOrder.externalId,
                        'Order Item'
                    );

                    orderResponseList.add(tempResponse);
                
                }
            }
        }
       

        
        orderExternalIds = String.join(externalIds, ',');

        IntegrationLog.createLog(
            'Order', orderExternalIds, 'Inbound', JSON.serialize(request),
            JSON.serialize(orderResponseList), endpoint, hasError,
            hasDeleted, errorMessage
        );

        return orderResponseList;
    }

    global class OrderResponse extends InResponse{
        //List<itemResponse> itens = new List<itemResponse>();
    }

    global class ItemResponse extends InResponse{}
}
