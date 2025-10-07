@RestResource(urlMapping='/orders/*')
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

        
        Set<Id> foundOrders = new Set<Id>();
        
        for(Order iOrder : ordersToUpsert){
            if(iOrder.id != null){
                foundOrders.add(iOrder.Id);
            }
        }
        
        Set<Id> foundItens = new Set<Id>();
        
        for(OrderItem iItem : itensToUpsert){
            if(iItem.id != null){
                foundItens.add(iItem.Id);
            }
        }
        
        
        
        List <OrderItem> itensToDelete = [
            SELECT Id, isDeletedExternal__c 
            FROM OrderItem WHERE OrderId IN :foundOrders
            AND ExternalId__c NOT IN :foundItens
        ];
        
        for(OrderItem iItem : itensToDelete){
            iItem.isDeletedExternal__c = true;
        }
        
        
        itensToUpsert = fillOrderItem(request);

        itensToUpsert.addAll(itensToDelete);

        
        if (!itensToUpsert.isEmpty()) Database.upsert(itensToUpsert, OrderItem.ExternalId__c, true);
        
        string errorMessage = '';
        
        for(Order iOrder : ordersToUpsert){
            
            OrderResponse tempResponse = new OrderResponse();
            
            tempResponse.success(iOrder.Id, iOrder.ExternalId__c, iOrder.getSObjectType().getDescribe().getName());
            
            for(OrderItem iOrderItem : itensToUpsert){
                itemResponse tempItemResponse = new itemResponse();
                
                if(iOrderItem.OrderId == iOrder.id){
                    tempItemResponse.success(iOrderItem.Id, iOrderItem.ExternalId__c, iOrderItem.getSObjectType().getDescribe().getName());
                    tempResponse.itens.add(tempItemResponse);
                }
                else{
                    if(iOrder.id != null){
                        tempItemResponse.error(iOrderItem.Id, iOrderItem.ExternalId__c, tempItemResponse.errorMessage , iOrderItem.getSObjectType().getDescribe().getName());

                    }
                    else{
                        tempItemResponse.error(iOrderItem.ExternalId__c, tempItemResponse.errorMessage, iOrderItem.getSObjectType().getDescribe().getName());

                    }

                    errorMessage += tempItemResponse.errorMessage + '\n';

                }
            }

            orderResponseList.add(tempResponse);

        }


        for(String str : externalIds){
            orderExternalIds += str + ',';
        }

        orderExternalIds = orderExternalIds.removeEnd(',');
        
        String integrationLogId = IntegrationLog.createLog(
            'Order', orderExternalIds, 'Inbound', JSON.serialize(request), JSON.serialize(orderResponseList), endpoint, hasError,
             hasDeleted, errorMessage
            
        );
            
        return orderResponseList;
    }

   
	global class OrderResponse extends InResponse{
        List<itemResponse> itens = new List<itemResponse>();
	}

    global class itemResponse extends InResponse{
	}



}
