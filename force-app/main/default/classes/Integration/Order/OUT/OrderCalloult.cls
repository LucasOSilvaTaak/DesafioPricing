global with sharing class OrderCalloult {

    public static CalloutIntegrationUtils.CalloutResponse processIntegration(Id orderId){

        Order parentOrder = [SELECT Id, ExternalId__c FROM Order WHERE Id = :orderId];
        
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
                if (orderMap.containsKey(respWrapper.SalesforceCode)) {
                    Order order = orderMap.get(respWrapper.SalesforceCode);
                    if (respWrapper.Error == 'TRUE') {
                        //Error Treatments
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

        String payload = JSON.serialize(request);
        
        String accessToken = '';
        
        String endPoint = (!Test.isRunningTest() ? 
            'callout:HANA_Oncoprod/PreConta_SFOut' : 
            'http://callout.My_Named_Credential.com/some/path');

        Map<String, String> headersMap = new Map<String, String>();
        headersMap.put('Content-type', 'application/json');
        headersMap.put('Authorization', 'Bearer ' + accessToken);
        
        CalloutIntegrationUtils.RequestResponseObject responseObject = CalloutIntegrationUtils.executeCallout(endPoint, payload, headersMap);

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
		//Account Fields
		public String orderNumber;
		
		public RequestParameters(Order order) {
			this.orderNumber = order.ExternalId__c;		
		}
	}

	public class ResponseParameters implements CalloutIntegrationUtils.CalloutResponseParsedData{
		public List<ResponseParametersWrapper> responses;

		public ResponseParameters(List<ResponseParametersWrapper> responses) {
			this.responses = responses;
		}
	}

	public class ResponseParametersWrapper {
		public String Status;
		public String Error;
		public String SalesforceCode;
		public String ERPCode;
	}



}
