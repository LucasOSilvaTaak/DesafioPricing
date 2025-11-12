public with sharing class GoalItemsSchedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GoalItemRecaulculateBatch(), 200);

    }


}