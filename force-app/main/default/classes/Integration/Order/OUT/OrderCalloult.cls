global with sharing class OrderCalloult {

    public static CalloutIntegrationUtils.CalloutResponse processIntegration(List<Id> orderIds){

        Order parentOrder = [
            SELECT Id, Account.ExternalId__c, ExternalId__c, order.PaymentCondition__r.ExternalId__c, EffectiveDate, 
                AccountAddress__r.ExternalId__c, FreightType__c, DistributionCenter__r.ExternalId__c, RepresentativeOrderNumber__c, 
                DeliveryDate__c, Status, Observation__c,
                (SELECT ExternalId__c, Product2.ExternalId__c, Quantity, UnitPrice, TotvsItem__c, ListPrice FROM OrderItems)
            FROM Order WHERE Id in :orderIds
        ];
        
        List<Order> allOrders = new List<Order>{parentOrder};
        
        CalloutIntegrationUtils.CalloutResponse calloutResponse = sendOrder(allOrders);

        if (calloutResponse.success) {
            
            ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;
            
            Map<String, Order> orderMap = new Map<String, Order>();

            for (Order order : allOrders) {
                orderMap.put(order.ExternalId__c, order);
            }

            List<Order> AccountList = new List<Order>();

            for (ResponseParametersWrapper respWrapper : resp.responses) {
                if (orderMap.containsKey(respWrapper.externalId)) {
                    Order order = orderMap.get(respWrapper.externalId);
                    if (respWrapper.hasError == true) {
                        
                    } else {
                        //Success Treatments
                    }
                    
                    AccountList.add(order);
                }
            }

            if (!AccountList.isEmpty()) {
                update AccountList;
            }
        }

        

        
        return calloutResponse;
    }

    public static CalloutIntegrationUtils.CalloutResponse sendOrder(List<Order> orders) {
            
        List<RequestParameters> request = new List<RequestParameters>();
		
        for (Order ord : orders) {
            
            request.add(new RequestParameters(ord));
        }
        
        Map<String, List<RequestParameters>> requestMap = new Map<String, List<RequestParameters>>();

        requestMap.put('request', request);

        String payload = JSON.serialize(requestMap);
        
        String accessToken = CalloutToken.retrieveToken();
        
        //String endPoint = 'https://empathetic-impala-m56ghx-dev-ed.trailblaze.my.salesforce.com/services/apexrest/upsertOrder/';
        String endPoint = 'https://curious-bear-cnl6iw-dev-ed.trailblaze.my.salesforce.com/services/apexrest/upsertOrder/';

        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer ' + accessToken);

        System.debug(payload);
        
        CalloutIntegrationUtils.RequestResponseObject responseObject = CalloutIntegrationUtils.executeCallout(endPoint, payload, headersMap);
        

        //Precisa testar o log
        String externalIdList = '';
        
        for (Order iOrder : orders) {
            if (iOrder.ExternalId__c != null) {
                externalIdList += (String.isBlank(externalIdList) ? '' : ',') + iOrder.ExternalId__c;
            }
        }


        IntegrationLog.createLog('Order', externalIdList, 'Outbound', payload, responseObject.response.getBody(), endPoint, !responseObject.success, false);

        if (responseObject.success) {

            HttpResponse response = responseObject.response;

            try {
                List<ResponseParametersWrapper> responses = 
                    (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);

                return new CalloutIntegrationUtils.CalloutResponse(new ResponseParameters(responses));

            } catch (Exception e) {
                
                String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();
                return new CalloutIntegrationUtils.CalloutResponse(defaultErrorMessage);
            }
        } else {
            return new CalloutIntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage());
        }
    }

	public class RequestParameters {
		//Order Fields
		public String accountCode; //Order Account ExternalId
		public String orderCode; //Order Account ExternalId
		public String paymentCode; //Payment conditiom
		public Date effectiveDate;
		public String addressCode;
		public String freightType;
		public String distributionCenterCode;
		public Date deliveryDate;
		public String status;
		public String obs;
        public List<OrderItemWrapper> orderItems = new List<OrderItemWrapper>();
        		
		public RequestParameters(Order order) {
            accountCode = order.Account.ExternalId__c;
            orderCode = order.ExternalId__c;
            paymentCode = order.PaymentCondition__r.ExternalId__c;
            effectiveDate = order.EffectiveDate;
            addressCode = order.AccountAddress__r.ExternalId__c;
            freightType = order.FreightType__c;
            distributionCenterCode = order.DistributionCenter__r.ExternalId__c;
            deliveryDate = order.DeliveryDate__c;
            obs = order.Observation__c;
            status = order.Status;
            
            orderItems = new List<OrderItemWrapper>();
            for(OrderItem orderItem : order.OrderItems) {
                OrderItemWrapper orderItemWrapper = new OrderItemWrapper(orderItem);
                orderItems.add(orderItemWrapper);
            }


		
        }
	}

	public class ResponseParameters implements CalloutIntegrationUtils.CalloutResponseParsedData{
		public List<ResponseParametersWrapper> responses;

		public ResponseParameters(List<ResponseParametersWrapper> responses) {
			this.responses = responses;
		}
	}

	public class ResponseParametersWrapper {
        public String salesforceId;
		public String externalId;
		public String sobjectType;
		public Boolean hasError;
		public String errorMessage;
	}

    	public String id;
		public String productCode; //Product Id
		public String itemCode; //External ID
		public Boolean totvsItem; //If it is a totvitem
		public Decimal unitPrice;
		public Decimal listPrice; //ListPrice
		public Decimal quantity;
		public String orderCode;


    private class OrderItemWrapper {


        //external id
        public String itemCode;

        public String productCode;

        //Order item inserted from TOTVS
        public Boolean totvsItem = true;

        public Decimal unitPrice;

        public Decimal quantity;
        
        //ListPrice
        public Decimal listPrice;

        public OrderItemWrapper(OrderItem orderItem){
            this.itemCode = orderItem.ExternalId__c;
            this.productCode = orderItem.Product2.ExternalId__c;
            this.unitPrice = orderItem.UnitPrice;
            this.quantity = orderItem.Quantity;
            this.listPrice = orderItem.ListPrice;
        }
        /*

        public Map<String,Object> serialise(){
            Map<String,String> OrderItens = new Map<String,String>();
            OrderItens.put('productCode',this.productCode);
            OrderItens.put('itemCode',this.itemCode);
            OrderItens.put('totvsItem',this.totvsItem);
            OrderItens.put('unitPrice',this.unitPrice);
            OrderItens.put('listPrice',this.ListPrice);
            OrderItens.put('quantity',this.quantity);

            return OrderItens;
        }
            */

    }



}
