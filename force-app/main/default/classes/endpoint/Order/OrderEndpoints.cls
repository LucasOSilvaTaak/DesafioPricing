@RestResource(urlMapping='/order/*')
global with sharing class OrderEndpoints {
    private class OrderWrapper {

        //cnpj
        public String clientCode;
        
        //payment condition
        public String conditionCode;

        public Date effectiveDate;

        public Id distributionCenter;

        //ExternalId
        public string orderNumber;

        public Date deliveryDate;

        public String freightType;

        //delivery date on erp
        public String deliveryDateERP;

        public String status;

        public String obs;

        public List<OrderItemWrapper> orderItems;
    }

    private class OrderItemWrapper {

        //Orderm item id
        public Id productCode;

        //external id
        public id orderitemCode;

        //Order item inserted TOTVS
        public Boolean totvsItem;

        public Date deliveryDate;

        public Decimal unitPrice;

        public Decimal motorPrice;

        public Decimal quantity;

        public String status;
    }

    private static List<Order> wrapOrder(List<OrderWrapper> wrappers) {
       
        List<Order> ordersToUpsert = new List<Order>();
       
        for (OrderWrapper iOrderWrapper : wrappers) {

            Order tempOrder = new Order();
            if(iOrderWrapper.clientCode != null) {

                tempOrder.Account = new Account(ExternalId__c = iOrderWrapper.clientCode);

                tempOrder.AccountAddress__r = new AccountAddress__c(ExternalId__c = iOrderWrapper.clientCode);
            }
            if (iOrderWrapper.conditionCode != null) tempOrder.PaymentCondition__c = iOrderWrapper.conditionCode;
            if (iOrderWrapper.effectiveDate != null) tempOrder.EffectiveDate = iOrderWrapper.effectiveDate;
            if (iOrderWrapper.freightType != null) tempOrder.FreightType__c = iOrderWrapper.freightType;
            if (iOrderWrapper.distributionCenter != null) tempOrder.DistributionCenter__c = iOrderWrapper.distributionCenter;
            if (iOrderWrapper.orderNumber != null) tempOrder.ExternalId__c = iOrderWrapper.orderNumber;
            if (iOrderWrapper.deliveryDate != null) tempOrder.DeliveryDate__c = iOrderWrapper.deliveryDate;
            if (iOrderWrapper.obs != null) tempOrder.Observation__c = iOrderWrapper.obs;   
            if (iOrderWrapper.status != null) tempOrder.Status = iOrderWrapper.status;   

            ordersToUpsert.add(tempOrder);
       
        }
        return ordersToUpsert;
    }

    private static List<OrderItem> wrapOrderItem(List<OrderWrapper> wrappers) {

        System.debug('wrappers: ' + wrappers);
        List<OrderItem> itemsToUpsert = new List<OrderItem>();

        for (OrderWrapper iOrderWrapper : wrappers) {
            
            if (iOrderWrapper.orderItems == null) continue;

            Id externalId = iOrderWrapper.orderNumber;

            for (OrderItemWrapper IOrderItemWrapper : iOrderWrapper.orderItems) {
                
                OrderItem tempOrderItem = new OrderItem();

                tempOrderItem.ExternalId__c = externalId;

                if (IOrderItemWrapper.productCode != null) tempOrderItem.Product2Id = IOrderItemWrapper.productCode;
                if (IOrderItemWrapper.orderitemCode != null) tempOrderItem.ExternalId__c = IOrderItemWrapper.orderitemCode;
                if (IOrderItemWrapper.deliveryDate != null) tempOrderItem.EndDate = IOrderItemWrapper.deliveryDate;
                if (IOrderItemWrapper.unitPrice != null) tempOrderItem.UnitPrice = IOrderItemWrapper.unitPrice;
                if (IOrderItemWrapper.motorPrice != null) tempOrderItem.ListPrice= IOrderItemWrapper.motorPrice;
                if (IOrderItemWrapper.quantity != null) tempOrderItem.Quantity= IOrderItemWrapper.quantity;

                itemsToUpsert.add(tempOrderItem);
            }
        }

        return itemsToUpsert;
    }

    private static Map<String,Object> responseBody(List<Order> orders, List<OrderItem> items) {
        Map<String, Object> responseBody = new Map<String, Object>();
        responseBody.put('status', 'success');

        Map<String,Object> ordersFormated = new Map<String,Object>();

        for(Order iOrder : orders){

            ordersFormated.put('SalesforceId', iOrder.Id);
            ordersFormated.put('externalCode', iOrder.ExternalId__c);
            ordersFormated.put('sObjectType', iOrder.getSObjectType().getDescribe().getName());

            Map<String,Object> itemsFormated = new Map<String,Object>();

            for(OrderItem iOrderItem : items){
                itemsFormated.put('SalesforceId', iOrderItem.Id);
                itemsFormated.put('externalCode', iOrderItem.ExternalId__c);
                itemsFormated.put('sObjectType', iOrderItem.getSObjectType().getDescribe().getName());
            }

            ordersFormated.put('items', itemsFormated);

        }

        responseBody.put('orders', ordersFormated);

        return responseBody;

    }

    @HttpPost
    global static void createOrderSalesforce() {

        RestRequest request  = RestContext.request;
        RestResponse response = RestContext.response;

        List<OrderWrapper> wrappers = (List<OrderWrapper>) JSON.deserialize(request.requestBody.toString(), List<OrderWrapper>.class);

        List<Order> ordersToUpsert = wrapOrder(wrappers);

        if (!ordersToUpsert.isEmpty()) Database.upsert(ordersToUpsert, Order.ExternalId__c, true);

        List<OrderItem> itemsToUpsert = wrapOrderItem(wrappers);
    
        if (!itemsToUpsert.isEmpty()) Database.upsert(itemsToUpsert, OrderItem.ExternalId__c, true);
            
        Map<String, Object> responseBody = responseBody(ordersToUpsert, itemsToUpsert);

        String jsonResponse = JSON.serializePretty(responseBody);

        insert new ApiLog__c(
            Request__c  = request.requestBody.toString(),
            Response__c = jsonResponse,
            From__c     = 'TOTVS',
            Endpoint__c = 'ORDER'
        );

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(jsonResponse);
    }

    @HttpPut
    global static void putOrderSalesforce() {


        RestRequest request  = RestContext.request;
        
        RestResponse response = RestContext.response;

        List<Order> orderList = (List<Order>) JSON.deserialize(request.requestBody.toString(), List<Order>.class);

        List<Order> toUpdate = new List<Order>();

        Set<Id> orderids = new Set<Id>();

        Set<String> orderExternalidsString = new Set<String> ();

        for(Order iOrder : orderList){
            
            if (iOrder.Id != null) orderids.add(iOrder.Id);
            
            if(iOrder.ExternalId__c != null) orderExternalidsString.add(iOrder.ExternalId__c);
        
        }

        List<Order> existingOrder = [
            SELECT Id, ExternalId__c
            FROM Order
            WHERE Id IN :orderids
            OR ExternalId__c IN :orderExternalidsString    
        ];

        for(Order iOrder : existingOrder){

            for(Order iOrder2 : orderList){
                if(iOrder.id == iOrder2.Id || iOrder.ExternalId__c == iOrder2.ExternalId__c){
                    
                    if(iOrder2.id == null) iOrder2.Id = iOrder.Id;

                    toUpdate.add(iOrder2);
                    break;
                }

            }
        }
    
        if (toUpdate.size() > 0) update toUpdate;


        Map<String, Object> responseBody = new Map<String, Object>();

        responseBody.put('status', 'success');

        String jsonResponse = JSON.serializePretty(responseBody);

        ApiLog__c log = new ApiLog__c(Request__c = request.requestBody.toString() , Response__c = jsonResponse, From__c = 'TOTVS', Endpoint__c = 'ORDER');
        Insert log;

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');

        response.responseBody = Blob.valueOf(jsonResponse);
  
    }

    @HttpDelete
    global static void deleteOrderSalesforce() {


        RestRequest request  = RestContext.request;
        
        RestResponse response = RestContext.response;

        List<Order> orderList = (List<Order>) JSON.deserialize(request.requestBody.toString(), List<Order>.class);
    
        if (orderList.size() > 0) delete orderList;


        Map<String, Object> responseBody = new Map<String, Object>();

        responseBody.put('status', 'success');
        responseBody.put('Order', orderList);

        String jsonResponse = JSON.serializePretty(responseBody);

        ApiLog__c log = new ApiLog__c(Request__c = request.requestBody.toString() , Response__c = jsonResponse, From__c = 'TOTVS', Endpoint__c = 'ORDER');
        Insert log;

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');

        response.responseBody = Blob.valueOf(jsonResponse);
  
    }
}