global with sharing class GoalsItemOrderBatch implements Database.Batchable<SObject>, Database.Stateful{

    Set<Id> seenIds = new Set<Id>();

    //Goal Itens já buscados
    Map<Id, GoalItem__c> goalItems = new  Map<Id, GoalItem__c>();


    Set<String> statusNotComplete = new Set<String>{
        'New',
        'Waiting Approval',
        'Integration Error'
    };

    Set<String> statusComplete = new Set<String>{
        'Approved',
        'Integrated'
    };

    global Iterable<SObject> start(Database.BatchableContext bc){

        //Fazer um batch de reset valores para rodar antes desse

        return Database.getQueryLocator([
            SELECT Id, OwnerId, Status, PaymentCondition__c
            FROM Order
            WHERE LastModifiedDate = THIS_YEAR
            Order by OwnerId
        ]);
        
    }

    global void execute(Database.BatchableContext bc, List<SObject > scope){

        Set<Id> OrderIds = new Set<Id>();
        List<GoalItem__c> goalsToUpdate = new List<GoalItem__c>();


        //Vendedores
        Set<Id> Sallers = new Set<Id>();

        //Loop para pegar os vendedores 
        for(SObject iSObject : scope){
            
            Order iOrder = (Order) iSObject;

            OrderIds.add(iOrder.Id);
            Sallers.add(iOrder.OwnerId);
            
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

        goalItems.putAll(GoalItemBatchHelper.getGoalItems(Sallers, goalItems)); 

        Map<Id,GoalItem__c> productGoals = new Map<Id,GoalItem__c>();
        Map<Id,GoalItem__c> productHierarchyGoals = new Map<Id,GoalItem__c>();
        Map<Id,GoalItem__c> paymentConditionGoals = new Map<Id,GoalItem__c>();
        Map<Id,GoalItem__c> performaceGoals = new Map<Id,GoalItem__c>();
        
        for (GoalItem__c iGoalItem : goalItems.values()){

            switch on iGoalItem.Type__c {
                when 'Product2' {
                    productGoals.put(iGoalItem.Product__c,iGoalItem);
                }
                when 'ProductHierarchy__c' { 
                    productHierarchyGoals.put(iGoalItem.ProductHierarchy__c,iGoalItem);
                }
                when 'PaymentCondition__c' {
                    paymentConditionGoals.put(iGoalItem.PaymentCondition__c,iGoalItem);
                }
                when 'Performance' {
                    performaceGoals.put(iGoalItem.Goal__r.Seller__c,iGoalItem);
                }
            }

        }

        List<OrderItem> productOrderItems = new List<OrderItem>();
        List<OrderItem> productHierarchyOrderItems = new List<OrderItem>();
        List<OrderItem> paymentConditionOrderItems = new List<OrderItem>();
        List<OrderItem> performanceOrderItems = new List<OrderItem>();

        for (OrderItem iOrdemItem : orderItems) {

            if (productGoals.containsKey(iOrdemItem.Product2Id)) {
                productOrderItems.add(iOrdemItem);
            }

            if (productHierarchyGoals.containsKey(iOrdemItem.Product2.ProductHierarchy__c)) {
                productHierarchyOrderItems.add(iOrdemItem);
            }

            if (paymentConditionGoals.containsKey(iOrdemItem.Order.PaymentCondition__c)) {
                paymentConditionOrderItems.add(iOrdemItem);
            }

            performanceOrderItems.add(iOrdemItem);
        }

        for( OrderItem iOrderItem : orderItems ){
            
            if(productGoals.containsKey(iOrderItem.Product2Id)){
                decideWichValueByOrderStatus(iOrderItem, productGoals.get(iOrderItem.Product2Id));
                seenIds.add(productGoals.get(iOrderItem.Product2Id).Id);
            }

            if(productHierarchyGoals.containsKey(iOrderItem.Product2.ProductHierarchy__c)){
                decideWichValueByOrderStatus(iOrderItem, productHierarchyGoals.get(iOrderItem.Product2.ProductHierarchy__c));
                seenIds.add(productHierarchyGoals.get(iOrderItem.Product2.ProductHierarchy__c).Id);
            }

            if(paymentConditionGoals.containsKey(iOrderItem.Order.PaymentCondition__c)){
                decideWichValueByOrderStatus(iOrderItem, paymentConditionGoals.get(iOrderItem.Order.PaymentCondition__c));
                seenIds.add(paymentConditionGoals.get(iOrderItem.Order.PaymentCondition__c).Id);
            }

            if(performaceGoals.containsKey(iOrderItem.Order.OwnerId)){
                decideWichValueByOrderStatus(iOrderItem, performaceGoals.get(iOrderItem.Order.OwnerId));
                seenIds.add(performaceGoals.get(iOrderItem.Order.OwnerId).Id);
            }
        }
        
                        
        for (Id iId : seenIds) 
            goalsToUpdate.add(goalItems.get(iId));
        

        if (!goalsToUpdate.isEmpty()){
            
            System.debug('goalsToUpdate - ' + goalsToUpdate);
            Database.update(goalsToUpdate, false);
        }

    }



   global void finish(Database.BatchableContext bc){
        Database.executeBatch(new GoalOpportunityBatch(), 200);

   }

   global void decideWichValueByOrderStatus(OrderItem iOrderItem, GoalItem__c iGoalItem){
        if(iOrderItem.Order.OwnerId == iGoalItem.Goal__r.Seller__c){
    
            if (statusComplete.contains(iOrderItem.Order.Status)) {
                iGoalItem.ValueAchieved__c += iOrderItem.Final__c;
                System.debug(iGoalItem.ValueAchieved__c);
            } 
            else if (statusNotComplete.contains(iOrderItem.Order.Status)) {
                iGoalItem.NegotiatedValue__c += iOrderItem.Final__c;
                System.debug(iGoalItem.NegotiatedValue__c);

            }

        }
   }
}