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
                field("DW Id"; Rec."DW Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to DynaicWeb User Id.';
                }
                field("Season No"; Rec."Season No")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to season.';
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
