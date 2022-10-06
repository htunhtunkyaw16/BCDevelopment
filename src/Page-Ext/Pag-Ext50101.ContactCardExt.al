/// <summary>
/// PageExtension ContactCardExt (ID 50101) extends Record Contact Card.
/// </summary>
pageextension 50101 ContactCardExt extends "Contact Card"
{
    layout
    {
        addafter("No.")
        {
            field(DWUserId; Rec.DWUserId)
            {
                ApplicationArea = All;
                Caption = 'DW User ID';
                Importance = Standard;

                trigger OnAssistEdit()
                begin
#pragma warning disable AL0604
                    if DWAssistEdit(xRec) then
#pragma warning restore AL0606
                        CurrPage.Update();
                end;
            }
        }
    }
}