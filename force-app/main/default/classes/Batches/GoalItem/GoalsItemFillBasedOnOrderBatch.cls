global with sharing class GoalsItemFillBasedOnOrderBatch implements Database.Batchable<SObject>, Database.Stateful{

    Set<Id> seenIds = new Set<Id>();

    Map<Id, GoalItem__c> goalItems = new  Map<Id, GoalItem__c>();

    GoalItemOrderBatchService service = new GoalItemOrderBatchService();

    global Iterable<SObject> start(Database.BatchableContext bc){

        return Database.getQueryLocator([
            SELECT Id, OwnerId, Status, PaymentCondition__c
            FROM Order
            WHERE LastModifiedDate = THIS_YEAR
            Order by OwnerId
        ]);
        
    }

    global void execute(Database.BatchableContext bc, List<SObject > scope){

        Map<Id, GoalItem__c> updatedGoals = service.setGoalItems(goalItems, scope);

        goalItems.putAll(updatedGoals);
        
        seenIds.addAll(updatedGoals.keySet());

        if (!updatedGoals.isEmpty()) {

            Database.update(updatedGoals.values(), false);

        }

    }



   global void finish(Database.BatchableContext bc){

   }

}