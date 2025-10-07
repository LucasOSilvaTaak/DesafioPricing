 public class RequestResponse{
    
    public HttpResponse response;
    public Boolean success;
    public Exception exceptionObject;

    public RequestResponse(HttpResponse response){
        this.success = true;
        this.response = response;
        this.exceptionObject = null;
    }

    public RequestResponse(Exception ex){
        this.success = false;
        this.response = null;
        this.exceptionObject = ex;
    }
}