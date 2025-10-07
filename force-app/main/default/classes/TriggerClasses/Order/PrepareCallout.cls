public with sharing class PrepareCallout {

        @Future(callout=true)
        public static void processIntegration(List<Id> orderIds){
            OrderOutbound.orderCalloult(orderIds);
        }

}