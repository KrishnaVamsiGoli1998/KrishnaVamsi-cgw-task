public class CreateInvoiceController {
    
    public String accountId { get; set; }
    public String lineItemDescription { get; set; }
    public String childRelationshipName { get; set; }
    public Decimal lineItemQuantity { get; set; }
    public Decimal lineItemUnitPrice { get; set; }
    public String invoiceDate { get; set; }
    public String invoiceDueDate { get; set; }
    public String originRecord { get; set; }
    public String orderId { get; set; }
    public List<OpportunityLineItem> lineItems { get; set; }
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
        
        
        
        System.debug('Child Relationship Name: ' + childRelationshipName);

        
        if (originRecord != null) {
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }
        if (originRecord != null) {
            isOpportunity = true;
            isOrder = false;
            
            lineItems = [SELECT Description, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :originRecord];
        }

        if (orderId != null) {
            isOrder = true;
            isOpportunity = false;
            
            orderItems = [SELECT Description, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :orderId];
        }
        
    }
    
   	public void generateJson() {
    System.debug('Debug: Entered generateJson method.');

    Map<String, Object> invoice = new Map<String, Object>();
    invoice.put('Type', 'ACCREC');
    invoice.put('Contact', new Map<String, Object>{'ContactID' => '0000000'});

    invoice.put('Date', invoiceDate != null ? invoiceDate : '');
    invoice.put('DueDate', invoiceDueDate != null ? invoiceDueDate : '');

    System.debug('Debug: Basic invoice setup completed.');

    List<Map<String, Object>> invoiceLineItems = new List<Map<String, Object>>();

    
    if (isOpportunity) {
        System.debug('Debug: Handling opportunity-related items.');
        if (lineItems != null) {
            for (OpportunityLineItem lineItem : lineItems) {
                if (lineItem != null) { // Check each item
                    System.debug('Debug: Processing OpportunityLineItem: ' + lineItem);
                    invoiceLineItems.add(new Map<String, Object>{
                        'Description' => lineItem.Description != null ? lineItem.Description : '',
                        'Quantity' => lineItem.Quantity != null ? lineItem.Quantity : 0,
                        'UnitAmount' => lineItem.UnitPrice != null ? lineItem.UnitPrice : 0,
                        'AccountCode' => '200'  
                    });
                } 
            }
        } 
    }

    if (isOrder) {
        System.debug('Debug: Handling order-related items.');
        if (orderItems != null) {
            for (OrderItem orderItem : orderItems) {
                if (orderItem != null) { 
                    System.debug('Debug: Processing OrderItem: ' + orderItem);
                    invoiceLineItems.add(new Map<String, Object>{
                        'Description' => orderItem.Description != null ? orderItem.Description : '',
                        'Quantity' => orderItem.Quantity != null ? orderItem.Quantity : 0,
                        'UnitAmount' => orderItem.UnitPrice != null ? orderItem.UnitPrice : 0,
                        'AccountCode' => '200'  
                    });
                } 
            }
        } 
    }

    System.debug('Debug: Invoice LineItems setup completed.');
    invoice.put('LineItems', invoiceLineItems);

    
    invoiceJson = JSON.serializePretty(invoice);

    System.debug('Debug: Generated JSON: ' + invoiceJson);
}


   
}
