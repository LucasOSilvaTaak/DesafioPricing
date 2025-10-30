public with sharing abstract class FilledObjects {
    
    public with sharing abstract class FilledObject {
        
        public String externalId {get; set;}
        public Boolean hasError {get; set;}
        public String errorMessage {get; set;}
        public Wrappers.Wrapper wrapper {get; set;}
        public SObject record {get; set;}


        public FilledObject(){
            this.hasError = false;
            this.errorMessage = '';
        
        }
        
    }
        
    public class FilledItem extends FilledObject {
                
        public FilledItem(){
            super();
            wrapper = new Wrappers.OrderItemWrapper();
            record = new OrderItem();
        }
    }

    public class FilledOrder extends FilledObject{
           
        public FilledOrder(){
            super();
            wrapper = new Wrappers.OrderWrapper();
            record = new Order();

        }
    }

    public class FilledDevUser extends FilledObject{

        public FilledDevUser(){
            super();
            wrapper = new Wrappers.DevUserWrapper();
            record = new DevUser__c();
        }
    }
    
}

