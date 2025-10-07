@RestResource(urlMapping='/order/*')
global with sharing class OrderInbound {

    private static List<OrderItem> fillOrderItem(List<Wrappers.OrderWrapper> orders) {

        List<OrderItem> itemsToUpsert = new List<OrderItem>();

        for(Wrappers.OrderWrapper iOrder : orders){

            if (iOrder.orderItems == null) continue;
            
            for(Wrappers.OrderItemWrapper iOrderItem : iOrder.orderItems){
                
                iOrderItem.orderCode = iOrder.orderCode;



                itemsToUpsert.add(iOrderItem.deserialize());
                
            }
        
        }


        return itemsToUpsert;

    }
    

    @HttpPost
    global static List<OrderResponse> createOrder(List<Wrappers.OrderWrapper> request) {

        Boolean hasError = false;
        Boolean hasDeleted = false;
        String orderExternalIds = '';

        List<Order> ordersToUpsert = new List<Order>();
    
        List<OrderItem> itensToUpsert = new List<OrderItem>();
    
        List<String> externalIds = new List<String>();

        List<OrderResponse> orderResponseList = new List<OrderResponse>();

        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/order/*';

        for (Wrappers.OrderWrapper iOrder : request) {

            externalIds.add(iOrder.orderCode);
            ordersToUpsert.add(iOrder.deserialize());

        }

        Map<String, String> orderExternalIdToOrderItem = new Map<String, String>();
        
        if (!ordersToUpsert.isEmpty()) Database.upsert(ordersToUpsert, Order.ExternalId__c, true);

        itensToUpsert = fillOrderItem(request);

        if (!itensToUpsert.isEmpty()) Database.upsert(itensToUpsert, OrderItem.ExternalId__c, true);

        for(Order iOrder : ordersToUpsert){

            OrderResponse tempResponse = new OrderResponse();
            
            tempResponse.success(iOrder.Id, iOrder.ExternalId__c, iOrder.getSObjectType().getDescribe().getName());
            
            for(OrderItem iOrderItem : itensToUpsert){

                if(iOrderItem.OrderId == iOrder.id){
                    itemResponse tempItemResponse = new itemResponse();
                    tempItemResponse.success(iOrderItem.Id, iOrderItem.ExternalId__c, iOrderItem.getSObjectType().getDescribe().getName());
                    tempResponse.itens.add(tempItemResponse);
                }
            }

            orderResponseList.add(tempResponse);

        }

        for(String str : externalIds){
            orderExternalIds += str + ',';
        }

        orderExternalIds = orderExternalIds.removeEnd(',');
        
        String integrationLogId = IntegrationLog.createLog(
            'Order', orderExternalIds, 'Inbound', JSON.serialize(request), JSON.serialize(orderResponseList), endpoint, hasError, hasDeleted
            
        );
            
        return orderResponseList;
    }

   
	global class OrderResponse extends InResponse{
        List<itemResponse> itens = new List<itemResponse>();
	}

    global class itemResponse extends InResponse{
	}



}
