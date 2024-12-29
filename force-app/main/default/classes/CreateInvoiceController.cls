public class CreateInvoiceController {

    public String accountId { get; set; }
    public String accountIdFinal { get; set; }
    public String lineItemDescription { get; set; }
    public String childRelationshipName { get; set; }
    public Decimal lineItemQuantity { get; set; }
    public Decimal lineItemUnitPrice { get; set; }
    public String invoiceDate { get; set; }
    public String invoiceDueDate { get; set; }
    public String originRecord { get; set; }
    public String orderId { get; set; }
    public List<OpportunityLineItem> lineItems { get; set; }
    public List<Line_Item__c> lineItemsToInsert { get; set; }
    public List<OrderItem> orderItems { get; set; }
    public Boolean isOpportunity { get; set; }
    public Boolean isOrder { get; set; }
    public String invoiceJson { get; set; }

    public CreateInvoiceController() {
        accountId = ApexPages.currentPage().getParameters().get('account');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        invoiceDate = ApexPages.currentPage().getParameters().get('invoice_date');
        invoiceDueDate = ApexPages.currentPage().getParameters().get('invoice_due_date');
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        orderId = ApexPages.currentPage().getParameters().get('order_id');
        childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        
        System.debug('Child Quantity: '+ApexPages.currentPage().getParameters().get('line_qty'));

        System.debug('Child Relationship Name: ' + childRelationshipName);

        if (originRecord != null) {
            isOpportunity = true;
            isOrder = false;
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }

        if (orderId != null) {
            isOrder = true;
            isOpportunity = false;
            accountIdFinal = [SELECT Id FROM Account WHERE AccountNumber = :accountId].Id;
            orderItems = [SELECT Description, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :orderId];
        }
    }

    public void generateJson() {
        System.debug('Debug: Entered generateJson method.');

        Map<String, Object> invoice = new Map<String, Object>();
        invoice.put('Type', 'ACCREC');
        invoice.put('Contact', new Map<String, Object>{ 'ContactID' => '0000000' });
        invoice.put('Date', invoiceDate != null ? invoiceDate : '');
        invoice.put('DueDate', invoiceDueDate != null ? invoiceDueDate : '');

        System.debug('Debug: Basic invoice setup completed.');

        List<Map<String, Object>> invoiceLineItems = new List<Map<String, Object>>();

        if (isOpportunity && lineItems != null) {
            for (OpportunityLineItem lineItem : lineItems) {
                invoiceLineItems.add(new Map<String, Object>{
                    'Description' => lineItem.Description != null ? lineItem.Description : '',
                    'Quantity' => lineItem.Quantity != null ? lineItem.Quantity : 0,
                    'UnitAmount' => lineItem.UnitPrice != null ? lineItem.UnitPrice : 0,
                    'AccountCode' => '200'
                });
            }
        }

        if (isOrder && orderItems != null) {
            for (OrderItem orderItem : orderItems) {
                invoiceLineItems.add(new Map<String, Object>{
                    'Description' => orderItem.Description != null ? orderItem.Description : '',
                    'Quantity' => orderItem.Quantity != null ? orderItem.Quantity : 0,
                    'UnitAmount' => orderItem.UnitPrice != null ? orderItem.UnitPrice : 0,
                    'AccountCode' => '200'
                });
            }
        }

        System.debug('Debug: Invoice LineItems setup completed.');
        invoice.put('LineItems', invoiceLineItems);

        invoiceJson = JSON.serializePretty(invoice);

        System.debug('Debug: Generated JSON: ' + invoiceJson);
    }

    public PageReference createInvoice() {
        Invoice__c newInvoice = new Invoice__c();

        if (isOpportunity) {
            newInvoice.Account__c = accountId;
        } else if (isOrder) {
            newInvoice.Account__c = accountIdFinal;
        }

        if (invoiceDate != null) {
            try {
                if (invoiceDate.contains('/')) {
                    List<String> dateParts = invoiceDate.split('/');
                    String formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];
                    newInvoice.Invoice_Date__c = Date.valueOf(formattedDate);
                } else {
                    newInvoice.Invoice_Date__c = Date.valueOf(invoiceDate);
                }
            } catch (Exception e) {
                newInvoice.Invoice_Date__c = Date.today();
            }
        } else {
            newInvoice.Invoice_Date__c = Date.today();
        }

        if (invoiceDueDate != null) {
            try {
                if (invoiceDueDate.contains('/')) {
                    List<String> dateParts = invoiceDueDate.split('/');
                    String formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];
                    newInvoice.Due_Date__c = Date.valueOf(formattedDate);
                } else {
                    newInvoice.Due_Date__c = Date.valueOf(invoiceDueDate);
                }
            } catch (Exception e) {
                newInvoice.Due_Date__c = Date.today().addDays(30);
            }
        } else {
            newInvoice.Due_Date__c = Date.today().addDays(30);
        }

        insert newInvoice;

        List<Line_Item__c> lineItemsToInsert = new List<Line_Item__c>();

        if (isOpportunity && lineItems != null) {
            for (OpportunityLineItem lineItem : lineItems) {
                lineItemsToInsert.add(new Line_Item__c(
                    Invoice__c = newInvoice.Id,
                    Line_Description__c = lineItem.Description,
                    Quantity__c = lineItem.Quantity,
                    Unit_Price__c = lineItem.UnitPrice
                ));
            }
        }

        if (isOrder && orderItems != null) {
            for (OrderItem orderItem : orderItems) {
                lineItemsToInsert.add(new Line_Item__c(
                    Invoice__c = newInvoice.Id,
                    Line_Description__c = orderItem.Description,
                    Quantity__c = orderItem.Quantity,
                    Unit_Price__c = orderItem.UnitPrice
                ));
            }
        }

        if (!lineItemsToInsert.isEmpty()) {
            insert lineItemsToInsert;
        }

        PageReference invoicePage = new PageReference('/' + newInvoice.Id);
        invoicePage.setRedirect(true);
        return invoicePage;
    }
}
