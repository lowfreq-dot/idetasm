unit Settings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ValEdit,
  ExtCtrls, GlobalIdent;

type
  { TFormSettings }

  TFormSettings = class(TForm)
    ButtonRewriteConfig: TButton;
    ButtonDosBoxDir: TButton;
    ButtonClose: TButton;
    ButtonTasmDir: TButton;
    ButtonSave: TButton;
    EditDosBoxDir: TEdit;
    EditTasmDir: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonDosBoxDirClick(Sender: TObject);
    procedure ButtonRewriteConfigClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RewriteConfigFile();
    procedure LoadConfigFile();
  private

  public

  end;

  ConfType = Record
    DosBoxDir:string[255];
    DosBoxEXE:string[255];
    TasmDir:string[255];
  end;

var
  FormSettings: TFormSettings;
  ConfFile:File of ConfType;
  RecData:ConfType;

implementation

{$R *.lfm}

{ TFormSettings }

procedure TFormSettings.FormCreate(Sender: TObject);
begin
     LoadConfigFile();
end;

procedure TFormSettings.ButtonDosBoxDirClick(Sender: TObject);
begin
     if SelectDirectoryDialog1.Execute then begin
        EditDosBoxDir.Text:=SelectDirectoryDialog1.FileName;
     end;
end;

procedure TFormSettings.ButtonCloseClick(Sender: TObject);
begin
     FormSettings.Hide;
end;

procedure TFormSettings.ButtonRewriteConfigClick(Sender: TObject);
begin
     RewriteConfigFile();
     LoadConfigFile();
end;

procedure TFormSettings.ButtonSaveClick(Sender: TObject);
begin
     AssignFile(ConfFile, 'ide.conf');
     if NOT FileExists('ide.conf') then
        RewriteConfigFile();
     Reset(ConfFile);

     RecData.DosBoxDir:=EditDosBoxDir.Text;
     RecData.DosBoxEXE:=RecData.DosBoxDir+'\DOSBox.EXE';
     RecData.TasmDir:=EditTasmDir.Text;

     Write(ConfFile, RecData);
     CloseFile(ConfFile);
     LoadConfigFile;
end;

procedure TFormSettings.LoadConfigFile();
begin
     AssignFile(ConfFile, 'ide.conf');
     if NOT FileExists('ide.conf') then begin
        RewriteConfigFile();
     end;
     Reset(ConfFile);
     Read(ConfFile, RecData);
     EditDosBoxDir.Text:=RecData.DosBoxDir;
     EditTasmDir.Text:=RecData.TasmDir;
     DosBoxDir:=RecData.DosBoxDir;
     DosBoxEXE:=RecData.DosBoxEXE;
     TasmDir:=RecData.TasmDir;
     CloseFile(ConfFile);
end;

procedure TFormSettings.RewriteConfigFile();
begin
     AssignFile(ConfFile, 'ide.conf');
     ReWrite(ConfFile);

     RecData.DosBoxDir:=GetCurrentDir()+'\user\DOSBox-0.74';
     RecData.DosBoxEXE:=RecData.DosBoxDir+'\DOSBox.EXE';
     RecData.TasmDir:=GetCurrentDir()+'\user\TASM';

     Write(ConfFile, RecData);
     CloseFile(ConfFile);
end;
end.
