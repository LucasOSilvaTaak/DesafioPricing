public with sharing class GoalSalesValueSchedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GoalResetBatch(), 200);

    }


}