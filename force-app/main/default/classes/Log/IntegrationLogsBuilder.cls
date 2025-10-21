public with sharing class IntegrationLogsBuilder {

    public class LogBuilder {
                
        private IntegrationLog__c log = new IntegrationLog__c();

        public LogBuilder reset() {
            this.log = new IntegrationLog__c();
            return this;
        }

        public LogBuilder setIntegrationName(String integrationName) {
            log.IntegrationName__c = integrationName;
            return this;
        }

        public LogBuilder setExternalIdList(String externalIdList) {
            log.ExternalIdList__c = externalIdList;
            return this;
        }

        public LogBuilder setIntegrationName(String type, String soObject) {
            log.Name = type + ' ' + soObject;

            return this;
        }

        public LogBuilder setPayloadIN(String payloadIN) {
            log.PayloadIN__c = payloadIN;
            return this;
        }

        public LogBuilder setPayloadOUT(String payloadOUT) {
            log.PayloadOUT__c = payloadOUT;
            return this;
        }

        public LogBuilder setEndpoint(String endpoint) {
            log.Endpoint__c = endpoint;
            return this;
        }

        public LogBuilder setExecutionDate(Datetime executionDate) {
            log.ExecutionDate__c = executionDate;
            return this;
        }

        public LogBuilder setHasDeleted(Boolean hasDeleted) {
            log.HasDeleted__c = hasDeleted;
            return this;
        }

        public LogBuilder setErrorMessage(String errorMessage) {
            log.ErrorMessage__c = errorMessage;
            return this;
        }

        public LogBuilder setHasAnyErrors(Boolean hasAnyErrors) {
            log.Status__c = hasAnyErrors ? 'Error' : 'Success';
            return this;
        }

        public IntegrationLog__c build() {
            return log;
        }

        public void insertBuild() {
            insert build();
            reset();
        }
    }
}
