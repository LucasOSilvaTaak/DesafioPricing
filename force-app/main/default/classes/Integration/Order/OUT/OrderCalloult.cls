public with sharing class OrderCalloult {


	public static IntegrationUtils.CalloutResponse processIntegration(Id orderId){

		Order parentOrder = [SELECT Id FROM Order WHERE Id = :orderId];
		
		List<Order> allOrders = new List<Order>{parentOrder};
		
		IntegrationUtils.CalloutResponse calloutResponse = sendOrder(allOrders);

		if (calloutResponse.success) {
			
			ResponseParameters resp = (ResponseParameters) calloutResponse.parsedResponse;
			
			Map<String, Order> orderMap = new Map<String, Order>();

			for (Order order : allOrders) {
				//ExternalKey
				orderMap.put(order.ExternalId__c, order);
			}

			List<Order> AccountList = new List<Order>();

			for (ResponseParametersWrapper respWrapper : resp.responses) {
				if (orderMap.containsKey(respWrapper.chaveSF)) {
					Order order = orderMap.get(respWrapper.chaveSF);
					if (respWrapper.erro == 'TRUE') {
						//Error Treatments
					} else {
						//Success Treatments\
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
	public static IntegrationUtils.CalloutResponse sendOrder(List<Order> orders) {
			
		List<RequestParameters> request = new List<RequestParameters>();

		for (Order ord : orders) {
			request.add(new RequestParameters(ord));
		}

		String payload = JSON.serialize(request);
		
		//Metodo para busca de Access Token, depende de cada projeto, podendo estar presente dentro de uma custom settings ou relacionado com outra requisição.
		String accessToken = '';
		
		//Path geralmente cadastrado dentro de ua customSettings
		String endPoint = (!Test.isRunningTest() ? 'callout:HANA_Oncoprod/PreConta_SFOut' : 'http://callout.My_Named_Credential.com/some/path');
		Map<String, String> headersMap = new Map<String, String>();
		headersMap.put('Content-type', 'application/json');
		headersMap.put('Authorization', 'Bearer ' + accessToken);
		
		IntegrationUtils.RequestResponseObject responseObject = IntegrationUtils.executeCallout(endPoint, payload, headersMap);

		if (responseObject.success) {

			HttpResponse response = responseObject.response;

			IntegrationUtils.WSLog('Conta', 'OUTBOUND', response.getBody(), payload, false);
			try {

				List<ResponseParametersWrapper> responses = (List<ResponseParametersWrapper>) JSON.deserialize(response.getBody(), List<ResponseParametersWrapper>.class);
				return new IntegrationUtils.CalloutResponse(new ResponseParameters(responses));
			} catch (Exception e) {
				
				String defaultErrorMessage = 'Malformatted HTTP Response Exception: ' + e.getMessage();

				return new IntegrationUtils.CalloutResponse(defaultErrorMessage);
			}
		} else {
			IntegrationUtils.WSLog('Ordem', 'OUTBOUND', responseObject.exceptionObject.getMessage(), payload, true);
			return new IntegrationUtils.CalloutResponse(responseObject.exceptionObject.getMessage());
		}
	}

	public class RequestParameters {
		//Account Fields
		public String AccountNumber;
		
		public RequestParameters(Account acc) {
			this.AccountNumber = acc.ExternalId__c;		
		}
	}

	public class ResponseParameters {
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