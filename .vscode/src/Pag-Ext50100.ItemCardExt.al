/// <summary>
/// PageExtension ItemCardExt (ID 50100) extends Record Item Card.
/// </summary>
pageextension 50100 ItemCardExt extends "Item Card"
{
    layout
    {
        addafter("No.")
        {
            field("No. 2"; Rec."No. 2")
            {
                Caption = 'No. 2';
                ApplicationArea = All;
            }
            field("Brand Code"; Rec."Brand Code")
            {
                Caption = 'Brand Code';
                ApplicationArea = All;
            }
            field("Repair Item"; Rec."Repair Item")
            {
                Caption = 'Repair Item';
                ApplicationArea = All;
            }
        }
        addafter(Warehouse)
        {
            group(Customization)
            {
                field(Remark; Rec.Remark)
                {
                    ApplicationArea = All;
                    Caption = 'Remark';
                }
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = ALl;
                    Caption = 'Sales Type';
                }
                field(Ecommerce; Rec.Ecommerce)
                {
                    ApplicationArea = All;
                    Caption = 'Ecommerce';
                }
                field(MFG; Rec.MFG)
                {
                    ApplicationArea = All;
                    Caption = 'MFG';
                }
                field("Competitive Price"; Rec."Competitive Price")
                {
                    ApplicationArea = All;
                    Caption = 'Competitive Price';
                }
                field(Rate; Rec.Rate)
                {
                    ApplicationArea = All;
                    Caption = 'Rate';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Name';
                    Editable = false;
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    ApplicationArea = All;
                    Caption = 'System Modified Date';
                }
                field("Life Cycle Starting Date"; Rec."Life Cycle Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Life Cycle Starting Date';
                }
                field("Lead Time"; Rec."Lead Time")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time';

                    trigger OnValidate()
                    begin
                        Rec."Life Cycle Ending Date" := CalcDate(Rec."Lead Time", Rec."Life Cycle Starting Date");
                    end;
                }
                field("Life Cycle Ending Date"; Rec."Life Cycle Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Life Cycle Ending Date';
                    Editable = false;
                }
                field(Season; Rec.Season)
                {
                    ApplicationArea = All;
                    Caption = 'Season';
                    TableRelation = Season."Season Code";
                }
            }
        }
        modify("Vendor No.")
        {
            trigger OnAfterValidate()
            begin
                if Vendor."No." = Rec."No." then
                    Rec."Vendor Name" := Vendor.Name;
                CurrPage.Update();
            end;
        }
    }

    var
        Vendor: Record Vendor;
}
