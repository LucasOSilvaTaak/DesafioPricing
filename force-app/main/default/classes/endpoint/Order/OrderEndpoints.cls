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
        public String orderitemCode;

        //Order item inserted from TOTVS
        public Boolean totvsItem;

        public Date deliveryDate;

        public Decimal unitPrice;

        //ListPrice
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

    private static List<OrderItem> wrapOrderItem(List<OrderWrapper> wrappers,Map<String, Id> orderIdsByExternal) {

        List<OrderItem> itemsToUpsert = new List<OrderItem>();

        for (OrderWrapper iOrderWrapper : wrappers) {
            if (iOrderWrapper.orderItems == null) continue;

            for (OrderItemWrapper IOrderItemWrapper : iOrderWrapper.orderItems) {

                OrderItem tempOrderItem = new OrderItem();

                if (iOrderWrapper.orderNumber != null &&
                    orderIdsByExternal.containsKey(iOrderWrapper.orderNumber)) {
                    tempOrderItem.OrderId = orderIdsByExternal.get(iOrderWrapper.orderNumber);
                }

                if (IOrderItemWrapper.productCode != null) tempOrderItem.Product2Id = IOrderItemWrapper.productCode;
                if (IOrderItemWrapper.orderitemCode != null) tempOrderItem.ExternalId__c = IOrderItemWrapper.orderitemCode;
                if (IOrderItemWrapper.deliveryDate != null) tempOrderItem.EndDate = IOrderItemWrapper.deliveryDate;
                if (IOrderItemWrapper.unitPrice != null) tempOrderItem.UnitPrice = IOrderItemWrapper.unitPrice;
                if (IOrderItemWrapper.motorPrice != null) tempOrderItem.ListPrice = IOrderItemWrapper.motorPrice;
                if (IOrderItemWrapper.quantity != null) tempOrderItem.Quantity = IOrderItemWrapper.quantity;

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
       
        Map<String, Id> orderIdsByExternal = new Map<String, Id>();
        for (Order iOrders : ordersToUpsert) {
            if (iOrders.ExternalId__c != null) {
                orderIdsByExternal.put(iOrders.ExternalId__c, iOrders.Id);
            }
        }

        List<OrderItem> itemsToUpsert = wrapOrderItem(wrappers, orderIdsByExternal);
    
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

        List<OrderWrapper> wrappers = (List<OrderWrapper>) JSON.deserialize(request.requestBody.toString(), List<OrderWrapper>.class);

        List<Order> ordersToUpdate = wrapOrder(wrappers);

        if (!ordersToUpdate.isEmpty()) {
            Database.upsert(ordersToUpdate, Order.ExternalId__c, true);
        }

        Map<String, Id> orderIdsByExternal = new Map<String, Id>();
        for (Order o : ordersToUpdate) {
            if (o.ExternalId__c != null) {
                orderIdsByExternal.put(o.ExternalId__c, o.Id);
            }
        }
        List<OrderItem> itemsToUpdate = wrapOrderItem(wrappers, orderIdsByExternal);

        if (!itemsToUpdate.isEmpty()) {
            Database.upsert(itemsToUpdate, OrderItem.ExternalId__c, true);
        }

        Map<String, Object> responseBody = responseBody(ordersToUpdate, itemsToUpdate);
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


    @HttpDelete
    global static void deleteOrderSalesforce() {


        RestRequest request  = RestContext.request;
        
        RestResponse response = RestContext.response;

        List<Id> orderItemListIds = (List<Id>) JSON.deserialize(request.requestBody.toString(), List<Id>.class);
        Set <Id> orderItemListIdsSet = new Set<Id>(orderItemListIds);


        List<OrderItem> orderList = [SELECT Id, ExternalId__c, isDeletedExternal__c FROM OrderItem WHERE Id IN :orderItemListIdsSet];
    
        for(OrderItem IorderItem : orderList){
            IorderItem.isDeletedExternal__c = true;
        }

        Update orderList;

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