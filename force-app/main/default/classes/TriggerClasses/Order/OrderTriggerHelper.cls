public with sharing class OrderTriggerHelper {

    public static void handleBeforeUpdate(List<Order> oldList, List<Order> newList){
        
        stopAccountChange(oldList, newList);

    }
    
    
    public static void handleAfterUpdate(List<Order> oldList, List<Order> newList){
      
        varifyOneItem(newList);
    }


    /*
    private static void prepareCallout(List<Order> oldList, List<Order> newList){
        Set<Id> setIds = new Set<Id>();
      
        for(Integer i = 0; i < newList.size(); i++){
            System.debug(newList[i].Status);

            if(newList[i].Status == 'Activated'){
      
                System.debug(newList[i].Status);
      
                setIds.add(newList[i].Id);
      
            }
        }

        if(setIds.size() > 0){
            PrepareCallout.processIntegration(new List<Id>(setIds));
        }
        
    }
    */

    //Deve ter no minimo um item por ordem
    private static void stopAccountChange(List<Order> oldList, List<Order> newList){
        
        for(Integer i = 0; i < newList.size(); i++){
        
            if(oldList[i].AccountId != newList[i].AccountId) {
        
                newList[i].addError('The Account cannot be changed');
        
            }
        }

    }

    private static void varifyOneItem(List<Order> newList){

        Set<Id> ordersId = new Set<Id>();

        for(Order iOrder : newList){

            ordersId.add(iOrder.Id);

        }

        Map<Id, OrderItem> orderMap = new Map<Id, OrderItem>();

        for(OrderItem iOrderItem : [
            SELECT Id, OrderId
            FROM OrderItem
            WHERE OrderId IN :ordersId
        ]){
            orderMap.put(iOrderItem.OrderId, iOrderItem);
        }


        for(Order iOrder : newList){

            if(iOrder.Status != 'New' && !orderMap.containsKey(iOrder.Id)  ){
                iOrder.addError('The Order must have at least one item');
            }
        }

    }

    
}