public with sharing class Wrappers {

	public interface Wrapper {
		void serialize(SObject record);
		SObject deserialize();
		String getFieldKey();
		String getFieldId();
		String getExternalId();
		Set<String> getRequiredFields();
		Map<String, String> getRequiredLookups();

	}


	public class OrderWrapper implements Wrapper {
        
		public String id;
		public String accountCode;
		public String orderCode;
		public String paymentCode;
		public Date effectiveDate;
		public String addressCode;
		public String freightType;
		public String distributionCenterCode;
		public Date deliveryDate;
		public String status;
		public String obs;

		public List<Wrappers.OrderItemWrapper> orderItems {
			get{

				for (Wrappers.OrderItemWrapper iItemWrapper : orderItems){
					
					iItemWrapper.orderCode = this.orderCode;
				}

				return orderItems;
				
			} 
			set ;
		}

		public SObject deserialize() {
			
			return new Order(
				Id = this.id,
				PaymentCondition__r = new PaymentCondition__c(ExternalId__c = this.paymentCode),
				EffectiveDate = this.effectiveDate,
				DistributionCenter__r = new DistributionCenter__c(ExternalId__c = this.distributionCenterCode),
				ExternalId__c = this.orderCode,
				DeliveryDate__c = this.deliveryDate,
				Status = 'New',
				Observation__c = this.obs,
				FreightType__c = this.freightType,
				Account = new Account(ExternalId__c = this.accountCode),
				AccountAddress__r = new AccountAddress__c(ExternalId__c = this.addressCode)
			);
		
		}

		public void serialize(SObject record) {
			
			Order order = (Order) record;
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
			
			for (OrderItem iOrderItem : order.OrderItems) {
			
				OrderItemWrapper iItemWrapper = new OrderItemWrapper();
				
				iItemWrapper.itemCode = iOrderItem.ExternalId__c;

				iItemWrapper.serialize(iOrderItem);
			
				orderItems.add(iItemWrapper);
			
			}
		}

		public Set<String> getRequiredFields() {
			return new Set<String>{
				'ExternalId__c',
				'EffectiveDate',
				'Status',
				'FreightType__c'
			};
		}

		public Map<String, String> getRequiredLookups() {
			return new Map<String, String>{
				'accountCode' => 'Account',
				'distributionCenterCode' => 'DistributionCenter__c',
				'addressCode' => 'AccountAddress__c',
				'paymentCode' => 'PaymentCondition__c'
			};
		}

		public String getFieldKey() { return 'ExternalId__c'; }
		public String getFieldId() { return 'Id'; }
		public String getExternalId() { return this.orderCode; }

	}

	public class OrderItemWrapper implements Wrapper {
        
		public String id;
		public String productCode;
		public String itemCode;
		public Boolean totvsItem = true;
		public Decimal unitPrice;
		public Decimal listPrice;
		public Decimal quantity;
		public String orderCode;

		public SObject deserialize() {
			
			OrderItem iOrderItem = new OrderItem(
				ExternalId__c = this.itemCode,
				UnitPrice = this.unitPrice,
				Quantity = this.quantity,
				TotvsItem__c = false,
				Product2 = new Product2(ExternalId__c = this.productCode)
			);
			
			if (String.isBlank(this.id)) {
			
				iOrderItem.Order = new Order(ExternalId__c = this.OrderCode);
			
				iOrderItem.ListPrice = this.listPrice;
		
			} 
			
			else {
			
				iOrderItem.Id = this.id;
			
			}
			
			return iOrderItem;
		}

		public void serialize(SObject record) {
			OrderItem orderItem = (OrderItem) record;
			itemCode = orderItem.OrderItemNumber;
			productCode = orderItem.Product2.ExternalId__c;
			unitPrice = orderItem.UnitPrice;
			quantity = orderItem.Quantity;
			listPrice = orderItem.ListPrice;
			orderCode = orderItem.OrderId;
		}

		public String getFieldKey() { return 'ExternalId__c'; }
		
		public String getFieldId() { return 'Id'; }
		
		public String getExternalId() { return this.itemCode; }

		public Set<String> getRequiredFields() {
			return new Set<String>{
				'ExternalId__c',
				'UnitPrice', 
				'Quantity',
				'ListPrice'
			};
		}

		public Map<String, String> getRequiredLookups() {
			return new Map<String, String>{
				'productCode' => 'Product2'
			};
		}

	}

	public class DevUserWrapper implements Wrapper{
		
		String login;
        String type;
        String bio;
        String Id;

		public void serialize(SObject record) {
            
			DevUser__c devUser = (DevUser__c) record;

			login = devUser.Login__c;
            type = devUser.Type__c;
            bio = devUser.Bio__c;
            id = devUser.ExternalId__c;
			

        }

        public SObject deserialize() {
            
			DevUser__c devUser = new DevUser__c(
                Login__c = login,
                Type__c = type,
                Bio__c = bio,
                ExternalId__c = Id
            );

            return devUser;
        }

		public String getFieldKey() { return 'ExternalId__c'; }
		
		public String getFieldId() { return 'Id'; }
		
		public String getExternalId() { return this.Id; }

		public Set<String> getRequiredFields() {
			return new Set<String>{
				'Login__c'
			};
		}

		public Map<String, String> getRequiredLookups() {
			return new Map<String, String>{
			};
		}

	}
	public class PokemonWrapper implements Wrapper{
		
		String name;
        String url;

		public void serialize(SObject record) {
            
			Pokemon__c pokemon = (Pokemon__c) record;

			name = pokemon.Name;
            url = pokemon.Url__c;
			

        }

        public SObject deserialize() {
            
			Pokemon__c pokemon = new Pokemon__c(
                Name = name,
                Url__c = url
            );

            return pokemon;
        }

		public String getFieldKey() { return ''; }
		
		public String getFieldId() { return ''; }
		
		public String getExternalId() { return null; }

		public Set<String> getRequiredFields() {
			return new Set<String>{
				'Name',
                'Url__c'
			};
		}

		public Map<String, String> getRequiredLookups() {
			return new Map<String, String>{
			};
		}

	}



}
