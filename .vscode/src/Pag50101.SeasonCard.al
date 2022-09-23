/// <summary>
/// Page Season Card (ID 50101).
/// </summary>
page 50101 "Season Card"
{
    Caption = 'Season Card';
    PageType = Card;
    SourceTable = Season;
    
    layout
    {
        area(content)
        {
            group(General)
            {
                field("Season Code"; Rec."Season Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Season Code field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Starting Date field.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Ending Date field.';
                }
            }
        }
    }
}
