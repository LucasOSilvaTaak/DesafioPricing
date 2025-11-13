public with sharing class GoalItemOpportunityBatchService implements GoalItemBatchServiceInterface {
    
    public Set<String> getStatusNotComplete(){
        return new Set<String>{
        };
    }

    public Set<String> getStatusComplete(){
        return new Set<String>{
            'Closed Won'
        };
    }
    
    public Map<Id, GoalItem__c> setGoalItems(Map<Id, GoalItem__c> goalItems, List<SObject> scope) {
                
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> sellers = new Set<Id>();
        Set<Id> seenIds = new Set<Id>();

        for (SObject iSObject : scope) {
            
            Opportunity iOpportunity = (Opportunity) iSObject;
            
            opportunityIds.add(iOpportunity.Id);
            
            sellers.add(iOpportunity.OwnerId);
        
        }

        List<OpportunityLineItem> opportunityItems = [
            SELECT Id,
                   Product2Id,
                   Product2.ProductHierarchy__c,
                   TotalPrice,
                   Opportunity.OwnerId,
                   Opportunity.StageName
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ];

        goalItems.putAll(GoalItemBatchHelper.getGoalItems(sellers, goalItems)); 

        Map<Id, GoalItem__c> productGoals = new Map<Id, GoalItem__c>();
        Map<Id, GoalItem__c> productHierarchyGoals = new Map<Id, GoalItem__c>();
        Map<Id, GoalItem__c> performanceGoals = new Map<Id, GoalItem__c>();
        
        for (GoalItem__c iGoalItem : goalItems.values()) {
            switch on iGoalItem.Type__c {
                when 'Product2' {
                    productGoals.put(iGoalItem.Product__c, iGoalItem);
                }
                when 'ProductHierarchy' { 
                    productHierarchyGoals.put(iGoalItem.ProductHierarchy__c, iGoalItem);
                }
                when 'Performance' {
                    performanceGoals.put(iGoalItem.Goal__r.Seller__c, iGoalItem);
                }
            }
        }

        for (OpportunityLineItem iOpportunityItem : opportunityItems) {
            decideWichValueByStatus(iOpportunityItem, productGoals.get(iOpportunityItem.Product2Id), seenIds);
            decideWichValueByStatus(iOpportunityItem, productHierarchyGoals.get(iOpportunityItem.Product2.ProductHierarchy__c), seenIds);
            decideWichValueByStatus(iOpportunityItem, performanceGoals.get(iOpportunityItem.Opportunity.OwnerId), seenIds);
        }
        
        Map<Id, GoalItem__c> result = new Map<Id, GoalItem__c>();
        
        for (Id iId : seenIds)
            result.put(iId, goalItems.get(iId));

        return result;
    }

    public void decideWichValueByStatus(SObject iObjectItem, GoalItem__c iGoalItem, Set<Id> seenIds) {
        
        if (iGoalItem == null) return;

        OpportunityLineItem iOpportunityItem = (OpportunityLineItem) iObjectItem;

        if (iOpportunityItem.Opportunity.OwnerId == iGoalItem.Goal__r.Seller__c) {
    
            if (getStatusComplete().contains(iOpportunityItem.Opportunity.StageName)) {
                iGoalItem.ProjectedValue__c += iOpportunityItem.TotalPrice;
            }

            seenIds.add(iGoalItem.Id);
        }
    }
}
