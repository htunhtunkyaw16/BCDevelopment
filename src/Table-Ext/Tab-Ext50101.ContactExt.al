/// <summary>
/// TableExtension ContactExt (ID 50101) extends Record Contact.
/// </summary>
tableextension 50101 ContactExt extends Contact
{
    fields
    {
        field(50101; "External No. Series"; Code[20])
        {
            Caption = 'External No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        modify("External ID")
        {
            trigger OnAfterValidate()
            begin
                if "External ID" <> Rec."External ID" then begin
                    CustomSetup.Get();
                    NoSeriesMgt.TestManual(CustomSetup."External Id");
                    "External No. Series" := '';
                end;
            end;
        }
    }

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;
        if "External ID" = '' then begin
            CustomSetup.Get();
            CustomSetup.TestField("External Id");
            NoSeriesMgt.InitSeries(CustomSetup."External Id", xRec."External No. Series", 0D, "External ID", "External No. Series");
        end;
    end;

    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CustomSetup: Record CustomFieldSetUp;

    /// <summary>
    /// ExternalAssistEdit.
    /// </summary>
    /// <param name="OldCont">Record Contact.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure ExternalAssistEdit(OldCont: Record Contact) Result: Boolean
    var
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldCont, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Cont := Rec;
        CustomSetup.Get();
        CustomSetup.TestField("External Id");
        if NoSeriesMgt.SelectSeries(CustomSetup."External Id", OldCont."External ID", Cont."External No. Series") then begin
            CustomSetup.Get();
            CustomSetup.TestField("External Id");
            NoSeriesMgt.SetSeries(Cont."External ID");
            OnAssistEditOnAfterNoSeriesMgtSetSeries(Cont, OldCont);
            Rec := Cont;
            exit(true);
        end;

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Contact: record Contact; OldContact: Record Contact; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditOnAfterNoSeriesMgtSetSeries(var Contact: Record Contact; OldContact: Record Contact)
    begin
    end;

}
