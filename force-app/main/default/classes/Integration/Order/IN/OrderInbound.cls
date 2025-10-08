@RestResource(urlMapping='/orders/*')
global with sharing class OrderInbound {

    private static List<OrderItem> fillOrderItem(List<Wrappers.OrderWrapper> orders, Map<String, OrderItem> existingItems) {

        List<OrderItem> itemsToUpsert = new List<OrderItem>();

        for(Wrappers.OrderWrapper iOrder : orders){
            if (iOrder.orderItems == null) continue;

            for(Wrappers.OrderItemWrapper iOrderItem : iOrder.orderItems){
                iOrderItem.orderCode = iOrder.orderCode;

                if (existingItems.containsKey(iOrderItem.itemCode)){
                    iOrderItem.id = existingItems.get(iOrderItem.itemCode).Id;
                } else {
                    iOrderItem.id = null;
                }

                itemsToUpsert.add(iOrderItem.deserialize());
            }
        }

        return itemsToUpsert;
    }

    private static Set<Id> getOrderIds(List<Order> ordersToUpsert){

        Set<Id> orderIds = new Set<Id>();

        for(Order iOrder : ordersToUpsert){
            
            if(iOrder.id != null){
            
                orderIds.add(iOrder.Id);
            
            }
        
        }

        return orderIds;
    }

    private static Set<String> getOrderExternalIds(List<Wrappers.OrderWrapper> ordersToUpsert){

        Set<String> orderExternalIds = new Set<String>();

        for(Wrappers.OrderWrapper iOrder : ordersToUpsert){
            
           if(iOrder.orderItems == null) continue;
            
            for(Wrappers.OrderItemWrapper iItemWrapper : iOrder.orderItems){
                orderExternalIds.add(iItemWrapper.itemCode);
            }
        
        }

        return orderExternalIds;
    }

    private static Map<String,OrderItem> getExistingOrders(List<Order> ordersToUpsert, List<Wrappers.OrderWrapper> request){

        Map<String, OrderItem> existingItems = new Map<String, OrderItem>();

        Set<Id> foundOrders = getOrderIds(ordersToUpsert);

        Set<String> externalIds = getOrderExternalIds(request);

        for(OrderItem item : [
            
            SELECT Id, ExternalId__c, OrderId
            FROM OrderItem
            WHERE OrderId IN :foundOrders
            AND ExternalId__c IN :externalIds
       
        ]) {
            existingItems.put(item.ExternalId__c, item);
        }

        return existingItems;
    }

    private static void DeleteItensNotFound (List<Order> ordersToUpsert, List<Wrappers.OrderWrapper> request){
        
        List<OrderItem> existingItems = new List<OrderItem>();

        Set<Id> foundOrders = getOrderIds(ordersToUpsert);

        Set<String> externalIds = getOrderExternalIds(request);

        for(OrderItem item : [
            
            SELECT Id, ExternalId__c, OrderId
            FROM OrderItem
            WHERE OrderId IN :foundOrders
            AND ExternalId__c not IN :externalIds
       
        ]) {
            existingItems.add(item);
        }

        if (!existingItems.isEmpty()) {
            Database.delete(existingItems, true);
        }
    }

    @HttpPost
    global static List<OrderResponse> createOrder(List<Wrappers.OrderWrapper> request) {

        Boolean hasError = false;
        Boolean hasDeleted = false;
        String orderExternalIds = '';
        String errorMessage = '';

        List<Order> ordersToUpsert = new List<Order>();
        List<OrderItem> itensToUpsert = new List<OrderItem>();
        List<String> externalIds = new List<String>();
        List<OrderResponse> orderResponseList = new List<OrderResponse>();
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/order/*';

        for (Wrappers.OrderWrapper iOrder : request) {
           
            externalIds.add(iOrder.orderCode);
        
            ordersToUpsert.add(iOrder.deserialize());
        
        }

        try{
           
            if (!ordersToUpsert.isEmpty()) Database.upsert(ordersToUpsert, Order.ExternalId__c, true);

            Map<String, OrderItem> existingItems = getExistingOrders(ordersToUpsert, request);

            itensToUpsert = fillOrderItem(request, existingItems);
            
            DeleteItensNotFound(ordersToUpsert, request);

            if (!itensToUpsert.isEmpty()) Database.upsert(itensToUpsert, OrderItem.ExternalId__c, true);

            for(Order iOrder : ordersToUpsert){
                OrderResponse tempOrderResponse = new OrderResponse();
                tempOrderResponse.success(iOrder.Id, iOrder.ExternalId__c, iOrder.getSObjectType().getDescribe().getName());

                /* depois vejo como fazer isso retornar uma lista de itens e suas respostas
                for(OrderItem iOrderItem : itensToUpsert){
                    itemResponse tempItemResponse = new itemResponse();
                    
                    //if (iOrderItem.OrderId == iOrder.id) continue;
                    
                    tempItemResponse.success(
                        iOrderItem.Id, 
                        iOrderItem.ExternalId__c,
                        iOrderItem.getSObjectType().getDescribe().getName()
                    );
                        
                        
                    tempOrderResponse.itens.add(tempItemResponse);
                }
                */
                orderResponseList.add(tempOrderResponse);

            }

        } catch (Exception e){
           
            hasError = true;
            errorMessage = e.getMessage();
            OrderResponse tempResponse = new OrderResponse();
            tempResponse.error(null, errorMessage, 'Order');
            orderResponseList.add(tempResponse);
        
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

    global class itemResponse extends InResponse{}
}
