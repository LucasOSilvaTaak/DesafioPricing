public with sharing class OrderTriggerUseCase {

    public static void stopAccountChange(List<Order> oldList, List<Order> newList){
        
        for(Integer i = 0; i < newList.size(); i++){
        
            if(oldList[i].AccountId != newList[i].AccountId) {
        
                newList[i].addError('The Account cannot be changed');
        
            }
        }

    }

    //Deve ter no minimo um item por ordem
    public static void verifyOneItem(List<Order> newList){

        Set<Id> ordersId = new Set<Id>();

        for(Order iOrder : newList){

            ordersId.add(iOrder.Id);

        }

        Map<Id, OrderItem> orderMap = new Map<Id, OrderItem>();

        for(OrderItem iOrderItem : [
            SELECT Id, OrderId, Final__c
            FROM OrderItem
            WHERE OrderId IN :ordersId
        ]){
            orderMap.put(iOrderItem.OrderId, iOrderItem);
        }


        for(Order iOrder : newList){

            if(iOrder.Status != 'New' && !orderMap.containsKey(iOrder.Id)  ){
                iOrder.addError('The Order must have at least one item');
            }
        }

    }

    public static void updateDiscount(List<Order> newList){
        
        map<Id,Order> ordersMap = new Map<Id,Order>();
        Set<Id> ordersIdSet = new Set<Id>();

        for(Order iOrder : newList){

            ordersMap.put(iOrder.Id, iOrder);
            ordersIdSet.add(iOrder.Id);
            iOrder.TotalDiscount__c = 0;
        }

        for( OrderItem iItem : [
            SELECT Discount__c, OrderId, Final__c
            FROM OrderItem
            WHERE OrderId  IN :ordersIdSet
        ]){

            ordersMap.get(iItem.OrderId).TotalDiscount__c += iItem.Final__c;

        }

        for(Order iOrder : newList){
            if(iOrder.TotalDiscount__c > 0)
                iOrder.discount__c = 100 *( (iOrder.TotalDiscount__c - iOrder.TotalAmount) / iOrder.TotalDiscount__c);

            else 
                iOrder.discount__c = 0;
        }
    }

    private static List<Order> varifyIfCallApprove(List<Order> newList){

        List <Order>  toApprove = new List<Order>();

        for(Order iOrder : newList){
            if(iOrder.Status == 'Waiting Approval'){

                if(iOrder.discount__c < 20) toApprove.add(iOrder);

                else iOrder.addError('To be approved it need to be less than 20% of discount');
                
            }
        }

        return toApprove;

    }

    public static void callApprovation(List<Order> newList){

        List<Order> toApprove = varifyIfCallApprove(newList);

        List<approval.processSubmitRequest> approvalProcessSubmitRequestList = new List<approval.processSubmitRequest>();

        for(Order iOrder : toApprove){

            approval.processSubmitRequest request = new approval.processSubmitRequest();

            request.setObjectId(iOrder.Id);
            
            request.setProcessDefinitionNameOrId(iOrder.Id);
            
            request.setProcessDefinitionNameOrId('OrderApproval');

//            request.setSubmitterId(UserInfo.getUserId());

            approvalProcessSubmitRequestList.add(Request);
            

        }

        List<Approval.processResult> result = Approval.process(approvalProcessSubmitRequestList);

    }

    public static void activateCallout(List<Order> newList){

        Set<Id> setIds = new Set<Id>();
        
        for(Integer i = 0; i < newList.size(); i++){
            System.debug(newList[i].Status);

            if(newList[i].Status == 'Approved'){
        
                System.debug(newList[i].Status);
        
                setIds.add(newList[i].Id);
        
            }
        }

        if(setIds.size() > 0){
            processIntegration(new List<Id>(setIds));
        }
        
    }


    @Future(callout=true)
    public static void processIntegration(List<Id> orderIds){
        OrderOutbound.orderCalloult(orderIds);
    }
}