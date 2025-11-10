global with sharing class GoalItemOpportunityBatch implements Database.Batchable<SObject>, Database.Stateful{

    Set<Id> seenIds = new Set<Id>();

    Set<String> statusComplete = new Set<String>{
        'Closed Won'
    };

    //Goal Itens já buscados
    Map<Id, GoalItem__c> goalItems = new  Map<Id, GoalItem__c>();
    
    global Iterable<SObject> start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE LastModifiedDate = THIS_YEAR
            Order by OwnerId

        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject > scope){
    
        List<GoalItem__c> goalsToUpdate = new List<GoalItem__c>();

        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> sellersId = new Set<Id>();

        for( SObject iSObject : scope){
           
            Opportunity iOpportunity = (Opportunity) iSObject;
            
            opportunityIds.add(iOpportunity.Id);
            sellersId.add(iOpportunity.OwnerId);
       
        }

        List<OpportunityLineItem> opportunityItems = [
            SELECT Id, Product2Id, 
            Product2.ProductHierarchy__c, 
            TotalPrice, Opportunity.PaymentCondition__c, 
            Opportunity.StageName,
            Opportunity.OwnerId
            FROM OpportunityLineItem
            WHERE OpportunityId IN : opportunityIds
        ];

        goalItems.putAll(GoalItemBatchHelper.getGoalItems(sellersId, goalItems));

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


        List<OpportunityLineItem> productOpportunityItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> productHierarchyOpportunityItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> paymentConditionOpportunityItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> performanceOpportunityItems = new List<OpportunityLineItem>();

        for (OpportunityLineItem iOpportunityItem : opportunityItems) {

            if (productGoals.containsKey(iOpportunityItem.Product2Id)) {
                productOpportunityItems.add(iOpportunityItem);
            }

            if (productHierarchyGoals.containsKey(iOpportunityItem.Product2.ProductHierarchy__c)) {
                productHierarchyOpportunityItems.add(iOpportunityItem);
            }

            if (paymentConditionGoals.containsKey(iOpportunityItem.Opportunity.PaymentCondition__c)) {
                paymentConditionOpportunityItems.add(iOpportunityItem);
            }

            performanceOpportunityItems.add(iOpportunityItem);
        }

        for(OpportunityLineItem iOpportunityItem : opportunityItems ){
            
            if(productGoals.containsKey(iOpportunityItem.Product2Id)){
                decideWichValueByOpportunityStatus(iOpportunityItem, productGoals.get(iOpportunityItem.Product2Id));
                seenIds.add(productGoals.get(iOpportunityItem.Product2Id).Id);
            }

            if(productHierarchyGoals.containsKey(iOpportunityItem.Product2.ProductHierarchy__c)){
                decideWichValueByOpportunityStatus(iOpportunityItem, productHierarchyGoals.get(iOpportunityItem.Product2.ProductHierarchy__c));
                seenIds.add(productHierarchyGoals.get(iOpportunityItem.Product2.ProductHierarchy__c).Id);
            }

            if(paymentConditionGoals.containsKey(iOpportunityItem.Opportunity.PaymentCondition__c)){
                decideWichValueByOpportunityStatus(iOpportunityItem, paymentConditionGoals.get(iOpportunityItem.Opportunity.PaymentCondition__c));
                seenIds.add(paymentConditionGoals.get(iOpportunityItem.Opportunity.PaymentCondition__c).Id);
            }

            if(performaceGoals.containsKey(iOpportunityItem.Opportunity.OwnerId)){
                decideWichValueByOpportunityStatus(iOpportunityItem, performaceGoals.get(iOpportunityItem.Opportunity.OwnerId));
                seenIds.add(performaceGoals.get(iOpportunityItem.Opportunity.OwnerId).Id);
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
    
    }

    global void decideWichValueByOpportunityStatus(OpportunityLineItem iOpportunityItem, GoalItem__c iGoalItem){
        if(iOpportunityItem.Opportunity.OwnerId == iGoalItem.Goal__r.Seller__c){
    
            if (statusComplete.contains(iOpportunityItem.Opportunity.StageName)) {
                iGoalItem.ProjectedValue__c += iOpportunityItem.TotalPrice;
            } 

        }
    }
}