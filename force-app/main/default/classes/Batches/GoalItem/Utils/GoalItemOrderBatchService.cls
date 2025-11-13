public with sharing class GoalItemOrderBatchService implements GoalItemBatchServiceInterface {
    
    public Set<String> getStatusNotComplete(){
        return new Set<String>{
            'Approved',
            'Integrated'
        };
    }

    public Set<String> getStatusComplete(){
        return new Set<String>{
            'New',
            'Waiting Approval',
            'Integration Error'
        };
    }
    
    
    public Map<Id,GoalItem__c> setGoalItems(Map<Id,GoalItem__c> goalItems, List<SObject> scope){
                
        Set<Id> orderIds = new Set<Id>();

        Set<Id> sellers = new Set<Id>();

        Set<Id> seenIds = new Set<Id>();



        for (SObject iSObject : scope) {
            
            Order iOrder = (Order) iSObject;

            orderIds.add(iOrder.Id);
            
            sellers.add(iOrder.OwnerId);
            
        }

        List<OrderItem> orderItems = new List<OrderItem>([
            SELECT Id,
                Product2Id,
                Product2.ProductHierarchy__c,
                Final__c,
                Order.PaymentCondition__c,
                Order.OwnerId,
                Order.Status
            FROM OrderItem
            WHERE OrderId IN :OrderIds
        ]);

        goalItems.putAll(GoalItemBatchHelper.getGoalItems(sellers, goalItems)); 

        Map<Id,GoalItem__c> productGoals = new Map<Id,GoalItem__c>();
        Map<Id,GoalItem__c> productHierarchyGoals = new Map<Id,GoalItem__c>();
        Map<Id,GoalItem__c> paymentConditionGoals = new Map<Id,GoalItem__c>();
        Map<Id,GoalItem__c> performaceGoals = new Map<Id,GoalItem__c>();
        
        for (GoalItem__c iGoalItem : goalItems.values()){

            switch on iGoalItem.Type__c {
                when 'Product2' {
                    productGoals.put(iGoalItem.Product__c,iGoalItem);
                }
                when 'ProductHierarchy' { 
                    productHierarchyGoals.put(iGoalItem.ProductHierarchy__c,iGoalItem);
                }
                when 'PaymentCondition' {
                    paymentConditionGoals.put(iGoalItem.PaymentCondition__c,iGoalItem);
                }
                when 'Performance' {
                    performaceGoals.put(iGoalItem.Goal__r.Seller__c,iGoalItem);
                }
            }

        }


        for (OrderItem iOrderItem : orderItems) {
            
            decideWichValueByStatus(iOrderItem, productGoals.get(iOrderItem.Product2Id), seenIds);
            
            decideWichValueByStatus(iOrderItem, productHierarchyGoals.get(iOrderItem.Product2.ProductHierarchy__c), seenIds);
            
            decideWichValueByStatus(iOrderItem, paymentConditionGoals.get(iOrderItem.Order.PaymentCondition__c), seenIds);
            
            decideWichValueByStatus(iOrderItem, performaceGoals.get(iOrderItem.Order.OwnerId), seenIds);
        }
        
                        
        Map<Id,GoalItem__c> result = new Map<Id,GoalItem__c>();

        for (Id iId : seenIds)
            result.put(iId, goalItems.get(iId));

        return result;

    }

    public void decideWichValueByStatus(SObject iObjectItem, GoalItem__c iGoalItem, Set<Id> seenIds){
        
        if (iGoalItem == null) return;

        OrderItem iOrderItem = (OrderItem) iObjectItem;

        if(iOrderItem.Order.OwnerId == iGoalItem.Goal__r.Seller__c){
    
            if (getStatusComplete().contains(iOrderItem.Order.Status)) {
                iGoalItem.ValueAchieved__c += iOrderItem.Final__c;
                System.debug(iGoalItem.ValueAchieved__c);
            } 
            else if (getStatusNotComplete().contains(iOrderItem.Order.Status)) {
                iGoalItem.NegotiatedValue__c += iOrderItem.Final__c;
                System.debug(iGoalItem.NegotiatedValue__c);

            }

            seenIds.add(iGoalItem.Id);

        }
    }
}