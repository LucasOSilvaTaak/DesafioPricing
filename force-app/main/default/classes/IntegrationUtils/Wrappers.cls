global with sharing class Wrappers {
 global class OrderWrapper {
        
		public String id;
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
		public List<OrderItemWrapper> orderItems {get; set;}


		public Order deserialize() {
			return new Order(
				Id								= this.id,
				PaymentCondition__r				= new PaymentCondition__c(ExternalId__c = this.paymentCode),
				EffectiveDate					= this.effectiveDate,
				DistributionCenter__r			= new DistributionCenter__c(ExternalId__c = this.distributionCenterCode),
				ExternalId__c					= this.orderCode,
				DeliveryDate__c					= this.deliveryDate,
				Status							= 'New',
				Observation__c					= this.obs,
				FreightType__c					= this.freightType,
				Account							= new Account(ExternalId__c = this.accountCode),
				AccountAddress__r				= new AccountAddress__c(ExternalId__c = this.addressCode)

			);
		}

		public void serialize(Order order){
			accountCode = order.Account.ExternalId__c;
            orderCode = order.OrderNumber;
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
                OrderItemWrapper orderItemWrapper = new OrderItemWrapper();
				orderItemWrapper.serialize(orderItem);
                orderItems.add(orderItemWrapper);
            }

		}

		public Set<String> getRequiredFields() {
			return new Set<String>{
				'ExternalId__c',
				'EffectiveDate',
				'Status'
			};
		}
		/*public Set<String> getRequiredLookups() {
			return new Set<String>{
				'AccountId',
				'DistributionCenter__c',
				'AccountAddress__c',
				'PaymentCondition__c'

			};
		}
		*/

		public Set<String> verifyRequiredLookups() {
			
			Set<String> missingFields = new Set<String>();

			if(accountCode == null || accountCode == ''){

				missingFields.add('Account');

			}
			
			if(distributionCenterCode == null || distributionCenterCode == ''){
				missingFields.add('DistributionCenter__c');
			}

			if(addressCode == null || addressCode == ''){
				missingFields.add('AccountAddress__c');
			}	

			if(paymentCode == null  || paymentCode == ''){
				missingFields.add('PaymentCondition__c');
			}

			return missingFields;
		}

		public String getFieldKey() {
			return 'ExternalId__c';
		}
		public String getFieldId() {
			return 'Id';
		}
		public String getExternalId() {
			return this.orderCode;
		}
		

    }

    public class OrderItemWrapper {
        
        public String id;
		public String productCode; //Product Id
		public String itemCode; //External ID
		public Boolean totvsItem = true; //If it is a totvitem
		public Decimal unitPrice;
		public Decimal listPrice; //ListPrice
		public Decimal quantity;
		public String orderCode;

		public OrderItem deserialize() {
			OrderItem orderItem = new OrderItem(
				ExternalId__c	= this.itemCode,
				UnitPrice		= this.unitPrice,
				Quantity		= this.quantity,
				TotvsItem__c	= false,
				Product2		= new Product2(ExternalId__c = this.productCode)
			);

			if (this.id == null || this.id == '') {
				orderItem.Order				= new Order(ExternalId__c = this.OrderCode);
				orderItem.ListPrice			= this.listPrice;
			}
			else orderItem.Id = this.id;

			return orderItem;
		}

		public void serialize(OrderItem orderItem){

			itemCode = orderItem.OrderItemNumber;
			productCode = orderItem.Product2.ExternalId__c;
			unitPrice = orderItem.UnitPrice;
			quantity = orderItem.Quantity;
			listPrice = orderItem.ListPrice;
			orderCode = orderItem.OrderId;
			
		}

		public Set<String> getRequiredFields() {
			return new Set<String>{
				'ExternalId__c',
				'UnitPrice',
				'Quantity',
				'ListPrice'
			};
			}
			
		/*
		public Set<String> getRequiredLookups() {
			return new Set<String>{
				'OrderId',
				'Product2Id'
			};
		}
		*/

		public Set<String> verifyRequiredLookups() {
			
			Set<String> missingFields = new Set<String>();

			if(orderCode == null || orderCode == ''){
				missingFields.add('OrderId');
			}

			if(productCode == null || productCode == ''){
				
				missingFields.add('Product2Id');

			}

			return missingFields;
		}


		public String getFieldId() {
			return id;
		}
		public String getFieldExternal() {
			return itemCode;
		}
		public String getParentId() {
			return orderCode;
		}


    }




}