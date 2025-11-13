public interface GoalItemBatchServiceInterface {

    Set<String> getStatusNotComplete();

    Set<String> getStatusComplete();

    Map<Id,GoalItem__c> setGoalItems(Map<Id,GoalItem__c> goalItems, List<SObject> orderList);

    void decideWichValueByStatus(SObject iObjectItem, GoalItem__c iGoalItem, Set<Id> seenIds);
}