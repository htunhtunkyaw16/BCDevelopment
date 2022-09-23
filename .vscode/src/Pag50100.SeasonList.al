/// <summary>
/// Page Season List (ID 50100).
/// </summary>
page 50100 "Season List"
{
    Caption = 'Season';
    PageType = List;
    SourceTable = Season;
    CardPageId = 50101;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
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
