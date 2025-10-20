global with sharing class DeleteOldLogsSchedule implements Schedulable{

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteOldLogsBatch());
    }

}