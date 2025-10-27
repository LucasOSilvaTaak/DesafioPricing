@isTest
private class DeleteOldLogsSchedule_Test {

    @TestSetup
    static void makeData(){


        IntegrationLog.createLog(
            'Teste', 'ExternalId', 'Inbound', 'request',
            'response', 'endpoint', false,
            false, 'errorMessage'
        );

        IntegrationLog__c log = [SELECT Id, CreatedDate FROM IntegrationLog__c LIMIT 1];

        Test.setCreatedDate(log.Id ,log.CreatedDate.addMonths(-7));
        
        update log;
        

    }
    
    @isTest
    static void testDeleteOldLogsSchedule(){
        
        Test.startTest();

            Database.executeBatch(new DeleteOldLogsBatch(), 1);


        Test.stopTest();
        
        List<IntegrationLog__c> logs = [SELECT Id FROM IntegrationLog__c];

        System.Assert.areEqual(0, logs.size(), 'O log deveria ter sido deletada');
        
        

    }

}