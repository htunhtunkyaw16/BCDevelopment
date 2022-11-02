/// <summary>
/// PageExtension PostedSalesInvoiceExt (ID 50104) extends Record Posted Sales Invoice.
/// </summary>
pageextension 50104 PostedSalesInvoiceExt extends "Posted Sales Invoice"
{
    layout
    {
        addafter("Sell-to Country/Region Code")
        {
            field("Sell-to E-Mail"; Rec."Sell-to E-Mail")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Email';
                Editable = false;
                Importance = Additional;
                ToolTip = 'Specifies the email of the customer on the sales document.';
            }
            field("Sell-to Phone No."; Rec."Sell-to Phone No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Phone No.';
                Editable = false;
                Importance = Additional;
                ToolTip = 'Specifies the phone number of the customer on the sales document.';
            }
        }
    }
}
