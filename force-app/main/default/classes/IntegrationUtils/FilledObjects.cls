public with sharing virtual class FilledObjects {
    
    public with sharing virtual class FilledObject {
        
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
    
}

