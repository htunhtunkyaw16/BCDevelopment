/// <summary>
/// TableExtension SalesHeaderExt (ID 50102) extends Record Sales Header.
/// </summary>
tableextension 50102 SalesHeaderExt extends "Sales Header"
{
    fields
    {
        field(50100; "Ship-to Email"; Text[100])
        {
            Caption = 'Ship-to Email';
            DataClassification = ToBeClassified;
        }
        field(50101; "Ship-to Phone No"; Text[20])
        {
            Caption = 'Ship-to Phone No.';
            DataClassification = ToBeClassified;
        }

        modify("Ship-to Code")
        {
            trigger OnAfterValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                CopyShipToAddress: Boolean;
            begin
                CopyShipToAddress := not IsCreditDocType();
                if CopyShipToAddress then
                    if "Ship-to Code" <> '' then begin
                        ShipToAddr.Get("Sell-to Customer No.", "Ship-to Code");
                        SetShipToCustomerAddressFieldsFromShipToAddr1(ShipToAddr);
                    end
                    else begin
                        if "Sell-to Customer No." <> '' then begin
                            GetCust("Sell-to Customer No.");
                            CopyShipToCustomerAddressFieldsFromCust(Customer);
                        end;
                    end;
            end;
        }
    }

    var
        CompanyInfo: Record "Company Information";

    /// <summary>
    /// CopySellToAddressToShipToAddress1.
    /// </summary>
    procedure CopySellToAddressToShipToAddress1()
    begin
        "Ship-to Email" := "Sell-to E-Mail";
        "Ship-to Phone No" := "Sell-to Phone No.";
    end;

    local procedure SetShipToCustomerAddressFieldsFromShipToAddr1(ShipToAddr: Record "Ship-to Address")
    var
        IsHandled: Boolean;
        ShouldCopyLocationCode: Boolean;
        Location: Record Location;
    begin
        IsHandled := false;
        if IsHandled then
            exit;

        "Ship-to Email" := ShipToAddr."E-Mail";
        "Ship-to Phone No" := ShipToAddr."Phone No.";
        ShouldCopyLocationCode := ShipToAddr."Location Code" <> '';

        if IsCreditDocType() then
            if ShouldCopyLocationCode then begin
                Location.Get(ShipToAddr."Location Code");
                SetShipToAddress1(Location."E-Mail", Location."Phone No.");
            end else begin
                CompanyInfo.Get();
                "Ship-to Code" := '';
                SetShipToAddress1(CompanyInfo."E-Mail", CompanyInfo."Phone No.");
            end;
    end;

    local procedure SetShipToAddress1(ShipToEmail: Text[80]; ShipToPhone: Text[30])
    begin
        "Ship-to Email" := ShipToEmail;
        "Ship-to Phone No" := ShipToPhone;
    end;

    local procedure SetCustomerLocationCode(SellToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        if IsHandled then
            exit;

        if SellToCustomer."Location Code" <> '' then
            Validate("Location Code", SellToCustomer."Location Code");
    end;
}
