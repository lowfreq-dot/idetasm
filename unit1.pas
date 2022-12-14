unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, Grids, ValEdit, ExtCtrls, ComCtrls, SynHighlighterAsm,
  laz.VirtualTrees, SynEdit, SynHighlighterAny, SynHighlighterCpp,
  SynHighlighterMulti, Types, LCLType, LclIntf, PopupNotifier, FileCtrl,
  ShellCtrls, Settings, GlobalIdent, About, CRC, md5, SynEditMarkupSpecialLine;

type
  { TFormMain }

  TFormMain = class(TForm)
    ImageList1: TImageList;
    ListBoxOutput: TListBox;
    MainMenu1: TMainMenu;
    MenuItemSettings: TMenuItem;
    MenuItemCopy: TMenuItem;
    MenuItemCloseDosBox: TMenuItem;
    MenuItemOptions: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemRunCompiledEXE: TMenuItem;
    MenuItemRunCompiledBuild: TMenuItem;
    MenuItemBuild: TMenuItem;
    MenuItemCompile: TMenuItem;
    MenuItemSaveAs: TMenuItem;
    MenuItemOpen: TMenuItem;
    MenuItemNew: TMenuItem;
    MenuItemSave: TMenuItem;
    MenuItemRun: TMenuItem;
    MenuItemFile: TMenuItem;
    OpenDialog1: TOpenDialog;
    PopupMenu1: TPopupMenu;
    Process1: TProcess;
    SaveDialog1: TSaveDialog;
    ShellTreeView1: TShellTreeView;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    SynAsmSyn1: TSynAsmSyn;
    SynEdit1: TSynEdit;
    TabControl1: TTabControl;
    TimerStatusBar: TTimer;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButtonRunCompiledBuild: TToolButton;
    ToolButtonSaveAs: TToolButton;
    ToolButtonSave: TToolButton;
    ToolButtonOpen: TToolButton;
    ToolButtonNew: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxOutputClick(Sender: TObject);
    procedure ListBoxOutputDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemBuildClick(Sender: TObject);
    procedure MenuItemCloseDosBoxClick(Sender: TObject);
    procedure MenuItemCompileClick(Sender: TObject);
    procedure MenuItemNewClick(Sender: TObject);
    procedure MenuItemRunCompiledBuildClick(Sender: TObject);
    procedure MenuItemSaveAsClick(Sender: TObject);
    procedure MenuItemOpenClick(Sender: TObject);
    procedure MenuItemSaveClick(Sender: TObject);
    procedure CreateCompileBat();
    procedure CreateBuildBat();
    procedure CurrentFileChanged(fName:string; cDir:String);

    function Compile(Sender: TObject):boolean;
    function Build(Sender: TObject; ext:string):boolean;
    procedure AddLog(const aStr: String; const aColor: TColor);
    procedure MenuItemSettingsClick(Sender: TObject);
    procedure ShellTreeView1GetSelectedIndex(Sender: TObject; Node: TTreeNode);
    procedure ShellTreeView1SelectionChanged(Sender: TObject);
    procedure SynEdit1Change(Sender: TObject);
    procedure SynEdit1SpecialLineColors(Sender: TObject; Line: integer;
      var Special: boolean; var FG, BG: TColor);
    //procedure SetDirsFromFile(ConfFileName:string);

    function TColorToHex(sColor:TColor):string;
    function HexToTColor(sColor:string):TColor;
    procedure TimerStatusBarTimer(Sender: TObject);
    procedure ToolBar1Click(Sender: TObject);
    function ValInArray(arr: array of integer; val:integer):boolean;
  private

  public

  end;

var
  FormMain: TFormMain;
  CurrentFile, CurrentFileMD5, CurrentDir, FileName, FileNameWithoutExt:string;
  HasUnSavedData:Boolean;
  ShellTreeViewLastSelection:TTreeNode;
  ErrLines:array of integer;

implementation

{$R *.lfm}

{ TFormMain }

//Форма создана
procedure TFormMain.FormCreate(Sender: TObject);
begin
     //SetDirsFromFile('ide.conf');
     SetLength(ErrLines, 1);
end;

procedure TFormMain.ListBoxOutputClick(Sender: TObject);
begin

end;

// Новый файл
procedure TFormMain.MenuItemNewClick(Sender: TObject);
begin
     // Добавить
     HasUnSavedData:=false;
     SynEdit1.Clear;
     CurrentFileChanged('', '');
end;

// Открыть существующий
procedure TFormMain.MenuItemOpenClick(Sender: TObject);
begin
     if OpenDialog1.Execute then begin
        SynEdit1.Lines.LoadFromFile(OpenDialog1.Filename);
        CurrentFileChanged(OpenDialog1.FileName, OpenDialog1.InitialDir);
     end;
     HasUnSavedData:=false;
end;

// Сохранить
procedure TFormMain.MenuItemSaveClick(Sender: TObject);
var tmp:string;
begin
     if CurrentFile <> '' then begin
        SynEdit1.Lines.SaveToFile(CurrentFile);
        HasUnSavedData:=false;
     end
     else
         MenuItemSaveAsClick(Sender);
end;

// Сохранить как
procedure TFormMain.MenuItemSaveAsClick(Sender: TObject);
var tmp:string;
begin
     if SaveDialog1.Execute then begin
        SynEdit1.Lines.SaveToFile(SaveDialog1.Filename);
        CurrentFileChanged(SaveDialog1.Filename, SaveDialog1.InitialDir);
        HasUnSavedData:=false;
     end;
end;

// Компилировать
procedure TFormMain.MenuItemCompileClick(Sender: TObject);
begin
     ListBoxOutput.Clear;
     Compile(Sender);
end;

// Собрать
procedure TFormMain.MenuItemBuildClick(Sender: TObject);
begin
     ListBoxOutput.Clear;
     Build(Sender, 'COM');
end;

procedure TFormMain.MenuItemCloseDosBoxClick(Sender: TObject);
begin
     if MenuItemCloseDosBox.Checked = true then

end;

// Компилировать собрать и запустить
procedure TFormMain.MenuItemRunCompiledBuildClick(Sender: TObject);
var
    s:string;
begin
     MenuItemSaveClick(Sender); // Сохранить
     ListBoxOutput.Clear; // Отчистить вывод

     if Compile(Sender) = false then
        Exit;
     if Build(Sender, 'COM') = false then
        Exit;
     if fileexists(CurrentDir+FileNameWithoutEXT+'.com') then begin
        RunCommandInDir(CurrentDir, DosBoxEXE, ['\' + FileNameWithoutEXT + '.com', '-c', 'cls', '-noconsole', '-conf', DosBoxDir+'\dosbox.conf', '-noautoexec'], s);
     end
     else MessageDlg('Файл ' + FileNameWithoutEXT + '.com не найден!', mtError, [mbCancel], 0);
end;

function TFormMain.Compile(Sender: TObject):boolean;
var s, AsmFile:string;
    LstFile:TextFile;
    Errors, ErrLine:integer;
begin
     MenuItemSaveClick(Sender); // Перед началом - сохранить файл

     SetLength(ErrLines, 0); // Обнулить массив содержащий строки с ошибками
     SetLength(ErrLines, 1); // Задать размерность массива 1

     AddLog('Начало компиляции...', clWhite);

     AsmFile:=CurrentDir+FileNameWithoutEXT+'.asm'; // Путь до исходного файла

     if NOT fileexists(AsmFile) then begin // Если файл не существует
         MessageDlg('Файл ' + AsmFile + ' не найден!', mtError, [mbCancel], 0);
         AddLog('Файл  "' + AsmFile + '" не найден', HexToTColor('FF6060'));
         AddLog('Компиляция завершена с ошибками.', HexToTColor('FF6060'));
         Exit(false); // Тогда выйти
     end;

     CreateCompileBat(); // Создать bat для компиляции
     if MenuItemCloseDosBox.Checked = true then // Если DOSBOX не нужно закрывать после компиляции
        RunCommandInDir(CurrentDir, DosBoxEXE, ['\COMPILE.bat', '-c', 'cls', '-noconsole'], s) // Выполняем компиляцию
     else RunCommandInDir(CurrentDir, DosBoxEXE, ['\COMPILE.bat', '-c', 'cls', '-noconsole', '-exit'], s); // Выполняем компиляцию
     //с атрибутом DosBox -exit, DoxBox закроется после выполнения COMPILE.bat

     // Проверка на ошибки
     AssignFile(LstFile, CurrentDir+FileNameWithoutEXT+'.lst');
     Errors:=0; // Счётчик ошибок, обнуляем
     if fileexists(CurrentDir+FileNameWithoutEXT+'.lst') then begin // Файл листинга содержит отладочную информацию
     // В том числе и информацию об ошибках и предупреждениях
        Reset(LstFile); // Открыть файл для чтения
        while not EOF(LstFile) do begin // Пока не достигнут конец файла
              ReadLn(LstFile, s); // Считываем следующую строку
              if s.Contains('Error Summary') then // Если строка содержит *Error Summary*
                 break; // Значит достигли блока с ошибками и предупреждениями, выходим
        end;

        while not EOF(LstFile) do begin
              ReadLn(LstFile, s); // Считываем строчку
              if s.Contains('**Error**') then begin // Если это ошибка
                AddLog(s, HexToTColor('FF6060')); // Выводим в output
                Errors+=1;
                ErrLine:=StrToInt(s.Substring(s.IndexOf('(')+1, s.IndexOf(')')-s.IndexOf('(')-1)); // Считываем строку ошибки
                ErrLines[Length(ErrLines)-1]:=ErrLine; // В массив добавляем строку с ошибкой
                SetLength(ErrLines, Length(ErrLines)+1); // Увеличиваем массив на 1 для следующей записи
             end;

             if s.Contains('*Warning*') then // Если это предупреждение
                AddLog(s, clYellow); // Выводим в output
        end;

        CloseFile(LstFile); // Закрываем файл

        if Errors > 0 then begin // Если ошибки есть
           AddLog('Компиляция завершена с ошибками.', HexToTColor('FF6060'));
           Exit(false); // Тогда выйти из функции
        end;
     end;

     if NOT fileexists(CurrentDir+FileNameWithoutEXT+'.obj') then begin // Если файл .obj не существует
        AddLog('Компиляция завершена с ошибками. Возможно файл пуст, либо к нему нет доступа', HexToTColor('FF6060'));
        Exit(false); // Тогда выйти
     end;

     AddLog('Компиляция завершена успешно.', HexToTColor('60FF60'));
     Exit(true); // Выйти, вернуть значение true
end;

// Создать bat для компиляции
procedure TFormMain.CreateCompileBat();
var BatFile:TextFile;
begin
     AssignFile(BatFile, CurrentDir+'COMPILE.BAT');
     Rewrite(BatFile); // Создать Bat файл со следующими коммандами
     WriteLn(BatFile, 'MOUNT E ' + TasmDir); // Смонтировать E в качестве папки TASM
     WriteLn(BatFile, 'set PATH=%PATH%;E:\'); // Добавить E в переменную PATH чтобы пользоваться коммандой TASM из любого каталога
     Writeln(BatFile, 'TASM /l /t ' + FileName); // Компилировать Файл c атрибутами /l (Создать файл листинга) /t
     CloseFile(BatFile);
end;

// Собрать
function TFormMain.Build(Sender: TObject; ext:string):boolean;
var
    s, ObjFile:string;
begin
     Build:=true;
     AddLog('Начало сборки...', clWhite);
     ObjFile:=CurrentDir+FileNameWithoutEXT+'.obj';

     if NOT fileexists(ObjFile) then begin
          MessageDlg('Файл ' + ObjFile + ' не найден!', mtError, [mbCancel], 0);
          AddLog('Файл ' + ObjFile + ' отсутствует', HexToTColor('FF6060'));
          AddLog('Сборка завершена с ошибками. ', HexToTColor('FF6060'));
          Build:=false;
          Exit; // Выход
     end;

     CreateBuildBat();
     if MenuItemCloseDosBox.Checked = true then
        RunCommandInDir(CurrentDir, DosBoxEXE,[
          '\BUILD.bat',
          '-c',
          'cls',
          '-noconsole'
          ],s)
     else RunCommandInDir(CurrentDir, DosBoxEXE,[
          '\BUILD.bat',
          '-c',
          'cls',
          '-noconsole',
          '-exit'
          ],s);

     AddLog('Сборка завершена успешно.', HexToTColor('60FF60'));
end;

// Создать bat для сборки
procedure TFormMain.CreateBuildBat();
var BatFile:TextFile;
begin
     AssignFile(BatFile, CurrentDir+'BUILD.BAT');
     Rewrite(BatFile);
     WriteLn(BatFile, 'MOUNT E ' + TasmDir);
     WriteLn(BatFile, 'set PATH=%PATH%;E:\');
     Writeln(BatFile, 'TLINK /t ' + FileNameWithoutEXT + '.obj');
     CloseFile(BatFile);
end;

// Вывести текст в output
procedure TFormMain.AddLog(const aStr: String; const aColor: TColor);
begin
  //Добавляем в качестве очередного элемента пару: строка + объект.
  //Но в качестве объекта передаём на самом деле сведения о цвете.
  //Т. е. таким образом мы добавляем информацию - строку и цвет фона,
  //который будет прорисован для этой строки.
  ListBoxOutput.Items.AddObject(aStr, TObject(IntPtr((aColor))));
end;

procedure TFormMain.MenuItemSettingsClick(Sender: TObject);
begin
     FormSettings.Show();
end;

procedure TFormMain.ShellTreeView1GetSelectedIndex(Sender: TObject;
  Node: TTreeNode);
begin
     //CurrentFileChanged(Node.Text, ShellTreeView1.Selected);]
     //ShowMessage(Node.Text);
end;

procedure TFormMain.ShellTreeView1SelectionChanged(Sender: TObject);
var path:string;
begin
     //ShowMessage(BoolToStr(SynEdit1.Stat));
     if ShellTreeView1.Selected = ShellTreeViewLastSelection then begin
        ShellTreeView1.Selected := ShellTreeViewLastSelection;
        Exit;
     end;
     if HasUnsavedData = true then begin
        Case QuestionDlg('DDD', 'Вы хотите сохранить изменения в файле "' + CurrentFile + '"?', mtConfirmation, [mrYes, mrNo, mrCancel], 0) of
          mrYes: MenuItemSaveClick(Sender);
          mrNo: ;
          mrCancel: begin ShellTreeView1.Selected := ShellTreeViewLastSelection; Exit end;
        end;
     end;
     SynEdit1.Lines.LoadFromFile(ShellTreeView1.Selected.GetTextPath);
     path:=ShellTreeView1.Selected.GetTextPath;
     path := path.Replace('/', '\');
     CurrentFileChanged(path, ShellTreeView1.Root);
     ShellTreeViewLastSelection:=ShellTreeView1.Selected
end;

// Текст в SynEdit
procedure TFormMain.SynEdit1Change(Sender: TObject);
var
    MD5, tmp:string;
begin
     MD5:=MD5Print(md5String(SynEdit1.Lines.Text)); // Получаем MD5 хэш текущего содержимого
     StatusBar1.Panels.Items[2].Text:=MD5;

     if NOT (MD5 = CurrentFileMD5) then begin // Если содержимое отличается
        if HasUnSavedData = false then HasUnSavedData:=True;
     end
     else begin
          if HasUnSavedData = true then HasUnSavedData:=false;
     end;
end;

// Отрисовка специальной строки, поисходит каждый кадр
procedure TFormMain.SynEdit1SpecialLineColors(Sender: TObject; Line: integer;
  var Special: boolean; var FG, BG: TColor);
begin
     if ValInArray(ErrLines, line) then begin
        Special:=true; // делаем строку специальной
        BG:=clRed; // меняем цвет
     end;
end;

// Находится ли число в массиве
function TFormMain.ValInArray(arr: array of integer; val:integer):boolean;
var i:integer;
begin
     for i:=0 to Length(arr)-1 do begin
         if arr[i] = val then
            Exit(true);
     end;
     Exit(false);
end;

// Отрисовка каждого предмета в ListBox (каждый кадр)
procedure TFormMain.ListBoxOutputDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
     with ListBoxOutput.Canvas do begin
          //Извлекаем сведения о цвете фона и задаём для кисти этот цвет.
          Brush.Color := TColor(PtrInt(ListBoxOutput.Items.Objects[Index]));
          //Закрашиваем прямоугольник, в который потом будет выведена строка.
          FillRect(ARect);
          if odSelected in State then begin // Если элемент выделен
             Brush.Color := HexToTColor('0078D7');
             FillRect(ARect); // Закрашиваем синим
          end;
          //Выводим текст строки.
         TextOut(ARect.Left, ARect.Top, ListBoxOutput.Items[Index]);
     end;
end;

procedure TFormMain.MenuItemAboutClick(Sender: TObject);
begin
     FormAbout.Show; // Показать форму о программе
end;

//Редактируемый файл изменён
procedure TFormMain.CurrentFileChanged(fName:string; cDir:String);
begin
     SetLength(ErrLines, 0);
     SetLength(ErrLines, 1);
     CurrentFile:=fname;
     CurrentDir:=cDir;
     FileName:=CurrentFile.Substring(CurrentFile.LastIndexOf('\')+1, CurrentFile.Length);
     FileNameWithoutExt:=FileName.Substring(0, FileName.Length-4);
     CurrentFileMD5:=MD5Print(md5String(SynEdit1.Lines.Text));
     Caption:='Turbo Assebmler IDE - ' + CurrentFile;
     ShellTreeView1.Root:=CurrentDir;
end;

//Переводит TColor в HEX
function TFormMain.TColorToHex(sColor:TColor):string;
begin
     Result :=
     IntToHex(GetRValue(sColor), 2) +
     IntToHex(GetGValue(sColor), 2) +
     IntToHex(GetBValue(sColor), 2) ;
end;

//Переводит HEX в TColor
function TFormMain.HexToTColor(sColor:string):TColor;
begin
     Result :=
     RGB(
     StrToInt('$'+Copy(sColor, 1, 2)),
     StrToInt('$'+Copy(sColor, 3, 2)),
     StrToInt('$'+Copy(sColor, 5, 2)));
end;

//Тамер 1 сек.
procedure TFormMain.TimerStatusBarTimer(Sender: TObject);
begin
     StatusBar1.Panels.Items[0].Text:=DosBoxDir;
     StatusBar1.Panels.Items[1].Text:=CurrentFileMD5;
end;

procedure TFormMain.ToolBar1Click(Sender: TObject);
begin

end;

end.

