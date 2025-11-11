global with sharing class GoalUpdateSalesValueBatch implements Database.Batchable<SObject> , Database.Stateful {

    Map<Id, Goal__c> goalsMap = new Map<Id, Goal__c>();


    Set<String> statusComplete = new Set<String>{
        'Approved',
        'Integrated'
    };

    global Iterable<SObject> start(Database.BatchableContext bc){

        Set<id> sallers = new Set<id>();

        for (Goal__c iGoals : [
            SELECT Id, Seller__c
            FROM Goal__c
            WHERE Year__c = :Date.today().year()
        ]) {
            sallers.add(iGoals.Seller__c);
        }


        return Database.getQueryLocator([
            SELECT Id, TotalDiscount__c, OwnerId
            FROM Order
            WHERE LastModifiedDate = THIS_YEAR
            AND status IN :statusComplete
            AND OwnerId IN :sallers
        ]);
    }


    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Order> orderList = new List<Order>();
        
        Set<Id> sellerIds = new Set<Id>();

        for (SObject iSObject : scope) {

            Order iOrder = (Order) iSObject;

            orderList.add(iOrder);

            sellerIds.add(iOrder.OwnerId);

        }

        for (Goal__c iGoal : [
            SELECT Id, Seller__c, SalesValue__c
            FROM Goal__c
            WHERE Year__c = :Date.today().year()
            AND Seller__c IN :sellerIds
        ]) {
            if (!goalsMap.containsKey(iGoal.Seller__c)) {
                goalsMap.put(iGoal.Seller__c, iGoal);
            }
        }

        for (Order iOrder : orderList) {
           
    
            if (goalsMap.containsKey(iOrder.OwnerId)) 
                goalsMap.get(iOrder.OwnerId).SalesValue__c += iOrder.TotalDiscount__c;

        }

        Database.update(goalsMap.values(), false);

    }


    global void finish(Database.BatchableContext bc){

    }

}