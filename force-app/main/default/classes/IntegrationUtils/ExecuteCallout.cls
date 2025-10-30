public with sharing class ExecuteCallout {

    public static RequestResponse executeCalloutPost(String endpoint, String payload, Map<String, String> headers){
        
        HttpRequest request = new HttpRequest(); 

        System.debug('endpoint: ' + endpoint);
        System.debug('payload: ' + payload);
        System.debug('headers: ' + headers);
        
        request.setMethod('POST');
        request.setTimeout(110000);
 
        request.setEndpoint(endpoint);
        request.setBody(payload);

        if (headers != null && headers.size() > 0){
            for (String headerKey : headers.keySet()){
                request.setHeader(headerKey, headers.get(headerKey));
            }
        }
        
        HttpResponse response;

        try{
            
            response = (new Http()).send(request);

            System.debug('response' + response);
            System.debug('response' + response.getBody());
            System.debug('response' + response.getStatusCode());
            
            if(response.getStatus()  != 'OK'){
            
                throw new CalloutException('Response Exception: ' + response.getStatus());
            
            }
            
            RequestResponse outResponse = new RequestResponse(response);
            return outResponse;
            
        }
        catch (Exception e){
            
            RequestResponse outResponse = new RequestResponse(response,e);
            return outResponse;
        
        }


    }
    public static HttpResponse executeCalloutGet(String endpoint, String payload, Map<String, String> headers){
        
        HttpRequest request = new HttpRequest();

        System.debug('endpoint: ' + endpoint);
        System.debug('payload: ' + payload);
        System.debug('headers: ' + headers);
        
        request.setMethod('GET');
        request.setTimeout(110000);
 
        request.setEndpoint(endpoint);
        request.setBody(payload);

        if (headers != null && headers.size() > 0){
            for (String headerKey : headers.keySet()){
                request.setHeader(headerKey, headers.get(headerKey));
            }
        }
        
        HttpResponse response;

        try{
            
            response = (new Http()).send(request);
        
            
        }
        catch (Exception e){
            
            response = new HttpResponse();
            response.setStatusCode(500);
            response.setStatus('Error');
            response.setBody(e.getMessage());
        }

        return response;


    }

    public static HttpResponse executeCalloutGet(String endpoint){
        
        HttpRequest request = new HttpRequest();

        System.debug('endpoint: ' + endpoint);
        
        request.setMethod('GET');
        request.setTimeout(110000);
 
        request.setEndpoint(endpoint);

        
        HttpResponse response;

        try{
            
            response = (new Http()).send(request);
        
            
        }
        catch (Exception e){
            
            response = new HttpResponse();
            response.setStatusCode(500);
            response.setStatus('Error');
            response.setBody(e.getMessage());
        }

        return response;


    }

}