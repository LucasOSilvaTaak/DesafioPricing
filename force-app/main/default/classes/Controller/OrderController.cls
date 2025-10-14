global with sharing class OrderController {
    
    @AuraEnabled
    public static void processIntegration(List<Id> orderIds){
        runIntegration(orderIds);
    }
    
        
    @future(callout=true)
    global static void runIntegration(List<Id> orderIds) {
        OrderOutbound.orderCalloult(orderIds);
    }

}