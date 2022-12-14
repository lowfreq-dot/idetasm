unit About;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFormAbout }

  TFormAbout = class(TForm)
    ButtonClose: TButton;
    Label1: TLabel;
    procedure ButtonCloseClick(Sender: TObject);
  private

  public

  end;

var
  FormAbout: TFormAbout;

implementation

{$R *.lfm}

{ TFormAbout }

procedure TFormAbout.ButtonCloseClick(Sender: TObject);
begin
     FormAbout.Hide();
end;

end.

