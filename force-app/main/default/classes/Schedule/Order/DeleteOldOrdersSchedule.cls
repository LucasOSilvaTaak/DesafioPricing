public with sharing class DeleteOldOrdersSchedule implements Schedulable{

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteOldOrdersBatch());
    }

}