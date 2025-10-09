public with sharing class OrderTriggerUseCase {
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

    public static void stopAccountChange(List<Order> oldList, List<Order> newList){
        
        for(Integer i = 0; i < newList.size(); i++){
        
            if(oldList[i].AccountId != newList[i].AccountId) {
        
                newList[i].addError('The Account cannot be changed');
        
            }
        }

    }

    //Deve ter no minimo um item por ordem
    public static void varifyOneItem(List<Order> newList){

        Set<Id> ordersId = new Set<Id>();

        for(Order iOrder : newList){

            ordersId.add(iOrder.Id);

        }

        Map<Id, OrderItem> orderMap = new Map<Id, OrderItem>();

        for(OrderItem iOrderItem : [
            SELECT Id, OrderId, Final__c
            FROM OrderItem
            WHERE OrderId IN :ordersId
        ]){
            orderMap.put(iOrderItem.OrderId, iOrderItem);
        }


        for(Order iOrder : newList){

            if(iOrder.Status != 'Draft' && !orderMap.containsKey(iOrder.Id)  ){
                iOrder.addError('The Order must have at least one item');
            }
        }

    }

    public static void updateDiscount(List<Order> newList){
        
        map<Id,Order> ordersMap = new Map<Id,Order>();
        Set<Id> ordersIdSet = new Set<Id>();

        for(Order iOrder : newList){

            ordersMap.put(iOrder.Id, iOrder);
            ordersIdSet.add(iOrder.Id);
            iOrder.TotalDiscount__c = 0;
        }

        for( OrderItem iItem : [
            SELECT Discount__c, OrderId, Final__c
            FROM OrderItem
            WHERE OrderId  IN :ordersIdSet
        ]){

            ordersMap.get(iItem.OrderId).TotalDiscount__c += iItem.Final__c;

        }

        for(Order iOrder : newList){
            if(iOrder.TotalDiscount__c > 0)
                iOrder.discount__c = 100 *( (iOrder.TotalDiscount__c - iOrder.TotalAmount) / iOrder.TotalDiscount__c);

            else 
                iOrder.discount__c = 0;
        }
    }
}