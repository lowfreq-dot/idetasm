program idetasm;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Unit1, Settings, GlobalIdent, About;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='Turbo Assembler IDE';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormSettings, FormSettings);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.Run;
end.

