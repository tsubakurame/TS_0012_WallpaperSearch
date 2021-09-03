unit ApProfileSettingComponentList;

interface
uses
  System.Generics.Collections, System.Classes,
  Fmx.Edit
  ;

type
  TApProfileSettingsComponentList = class(TList<TCustomEdit>)
    private
      FOnChange : TNotifyEvent;
      procedure SetOnChange(evnt:TNotifyEvent);
      function GetOnChange:TNotifyEvent;
    public
      procedure OnChangeOff;
      procedure OnChangeOn;
      property OnChange : TNotifyEvent read GetOnChange write SetOnChange;
  end;

implementation

procedure TApProfileSettingsComponentList.SetOnChange(evnt: TNotifyEvent);
var
  edt : TCustomEdit;
begin
  FOnChange := evnt;
  for edt in Self do
    edt.OnChange  := FOnChange;
end;

function TApProfileSettingsComponentList.GetOnChange: TNotifyEvent;
begin
  Result  := FOnChange;
end;

procedure TApProfileSettingsComponentList.OnChangeOff;
var
  edt : TCustomEdit;
begin
  for edt in Self do edt.OnChange := nil;
end;

procedure TApProfileSettingsComponentList.OnChangeOn;
var
  edt : TCustomEdit;
begin
  for edt in Self do edt.OnChange := FOnChange;
end;

end.
