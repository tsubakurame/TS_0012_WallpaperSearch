program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit2 in 'Unit2.pas' {Form2},
  ApWorkThread in 'ApWorkThread.pas',
  ApModules in 'ApModules.pas',
  ApProfileSettingComponentList in 'ApProfileSettingComponentList.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.