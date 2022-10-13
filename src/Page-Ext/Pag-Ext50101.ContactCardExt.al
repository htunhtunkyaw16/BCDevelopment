/// <summary>
/// PageExtension ContactCardExt (ID 50101) extends Record Contact Card.
/// </summary>
pageextension 50101 ContactCardExt extends "Contact Card"
{
    layout
    {
        addafter("No.")
        {
            field("External ID";Rec."External ID")
            {
                ApplicationArea = All;
                Caption = 'External ID';
                Importance = Standard;

                trigger OnAssistEdit()
                begin
                    if Rec.ExternalAssistEdit(xRec) then
                        CurrPage.Update();
                end;
            }
        }
    }
}
