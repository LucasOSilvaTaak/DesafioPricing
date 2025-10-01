global without sharing class CalloutIntegrationUtils {

    public static Boolean SYSTEM_DEBUG_ENABLED   = true;

    // Standard Http Request response
    public class RequestResponseObject {
        // Response object, in case the callout was successful.
        public HttpResponse response;
        // Boolean that determines if there is an exception or a HttpResponse.
        public Boolean success;
        // Exception object, in case there is any.
        public Exception exceptionObject;

        public RequestResponseObject(HttpResponse response){
            this.success = true;
            this.response = response;
            this.exceptionObject = null;
        }

        public RequestResponseObject(Exception ex){
            this.success = false;
            this.response = null;
            this.exceptionObject = ex;
        }
    }

    
    // CALLOUT STANDARD RESPONSE OUTTER CLASS
    public class CalloutResponse{
		public CalloutResponseParsedData parsedResponse;
		public Boolean success;
		public String errorMessage;

		public CalloutResponse(CalloutResponseParsedData response){
			this.success = true;
			this.errorMessage = '';
			this.parsedResponse = response;
		}

		public CalloutResponse(String errorMessage){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponse = null;
		}

        public CalloutResponse(String errorMessage, CalloutResponseParsedData response){
			this.success = false;
			this.errorMessage = errorMessage;
			this.parsedResponse = response;
		}
	}
    // CALLOUT PARSING INNER INTERFACE
    public interface CalloutResponseParsedData{}

    public static RequestResponseObject executeCallout(String namedCredential, String payload, Map<String, String> requestHeaders){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        // Timeout reduced in 10000 miliseconds in order to avoid timeouts in invoke actions through javascript.
        request.setTimeout(110000);
        request.setEndpoint(namedCredential);
        request.setBody(payload);

        
        if (requestHeaders != null && requestHeaders.size() > 0){
            for (String headerKey : requestHeaders.keySet()){
                request.setHeader(headerKey, requestHeaders.get(headerKey));
            }
        }

        Long microtime = (Datetime.now()).getTime();
        if (SYSTEM_DEBUG_ENABLED){
            System.debug('EXECUTING WITH NAMED CREDENTIAL: '+namedCredential);
            System.debug('METHOD USED: '+request.getMethod());
            System.debug('SENT PAYLOAD: '+payload);
            System.debug('SENT HEADERS: '+JSON.serializePretty(requestHeaders));
        }

        HttpResponse response;
        try {
            response = (new Http()).send(request);

            if (SYSTEM_DEBUG_ENABLED){
                System.debug('RESPONSE IN '+((Datetime.now()).getTime() - microtime));
                System.debug('RESPONSE STATUS: '+response.getStatus()+' - '+String.valueOf(response.getStatusCode()));
                for (String headerKey : response.getHeaderKeys()){
                    if (String.isNotBlank(headerKey)) System.debug('HEADER KEY: '+headerKey+' | VALUE: '+response.getHeader(headerKey));
                }

                System.debug('RESPONSE BODY: '+response.getBody());
            }

            return new RequestResponseObject(response);
        } catch (Exception ex) {
            if (SYSTEM_DEBUG_ENABLED) System.debug('CALLOUT EXCEPTION: '+ex.getMessage());

            return new RequestResponseObject(ex);
        }
    }

}