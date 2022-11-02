/// <summary>
/// PageExtension SalesOrdersExt (ID 50103) extends Record Sales Orders.
/// </summary>
pageextension 50103 SalesOrdersExt extends "Sales Order"
{
    layout
    {
        addlast(Control4)
        {
            field("Ship-to Email"; Rec."Ship-to Email")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-mail';
                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                QuickEntry = false;
                ToolTip = 'Specifies ship to email address information.';
            }
            field("Ship-to Phone No"; Rec."Ship-to Phone No")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Phone No.';
                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                QuickEntry = false;
                ToolTip = 'Specifies phone no information.';
            }
        }
        modify(ShippingOptions)
        {
            trigger OnAfterValidate()
            begin
                if ShipToOptions = ShipToOptions::"Default (Sell-to Address)" then
                    Rec.CopySellToAddressToShipToAddress1();
            end;
        }
    }

}
