global with sharing class GoalItemFillBasedOnOpportunityBatch implements Database.Batchable<SObject>, Database.Stateful {

    Map<Id, GoalItem__c> goalItems = new Map<Id, GoalItem__c>();

    GoalItemBatchServiceInterface service = new GoalItemOpportunityBatchService();

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE LastModifiedDate = THIS_YEAR
            ORDER BY OwnerId
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        Map<Id, GoalItem__c> goalsToUpdate = service.setGoalItems(goalItems, scope);

        if (!goalsToUpdate.isEmpty()) {
           
            Database.update(goalsToUpdate.values(), false);
       
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}
