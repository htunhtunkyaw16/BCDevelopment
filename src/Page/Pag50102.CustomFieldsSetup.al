/// <summary>
/// Page CustomFieldsSetup (ID 50102).
/// </summary>
page 50102 CustomFieldsSetup
{
    Caption = 'Custom Fields Setup';
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    PageType = Card;
    SourceTable = CustomFieldSetUp;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("External Id"; Rec."External Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to External Id.';
                }
                field("Season No"; Rec."Season No")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to season.';
                }
                field("Default Location Code"; Rec."Default Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the default location to use when assigning location to create order.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
