unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Windows, DB, SdfData;

type

  { TForm1 }

  TForm1 = class(TForm)
    AboutButton: TButton;
    AutoSaveCheck: TCheckBox;
    AutoHold: TLabel;
    AutoHoldPanel: TPanel;
    SwitchTimer: TButton;
    IntervalSet: TEdit;
    HoldData: TButton;
    Label1: TLabel;
    Label2: TLabel;
    maccode: TLabel;
    OutputArea: TMemo;
    Save: TButton;
    ConnectPort: TButton;
    SaveDialog1: TSaveDialog;
    ExpDataSet: TSdfDataSet;
    SelectPort: TComboBox;
    HoldInterval: TTimer;
    procedure AboutButtonClick(Sender: TObject);
    procedure ConnectPortClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HoldDataClick(Sender: TObject);
    procedure HoldIntervalTimer(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SwitchTimerClick(Sender: TObject);
  private
    procedure StartTimer;
    procedure StopTimer;
  public

  end;

var
  Form1: TForm1;
  port: HANDLE;
  msg: array[0..1024] of char;
  FileName: string;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ConnectPortClick(Sender: TObject);
var
  PortInfo: DCB;
  ErrorCode: DWORD;
begin
  port := CreateFile(PChar(SelectPort.Text), GENERIC_READ, 0, nil, OPEN_EXISTING,
    0, 0);
  if port = -1 then
  begin       
    ErrorCode := GetLastError();
    ShowMessage('Oops, open '+ SelectPort.Text + ' failed!');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, ErrorCode, LANG_NEUTRAL,
      LPSTR(@msg), 1024, nil);
    MessageBoxA(Form1.Handle, LPCSTR(@msg), LPCSTR(Form1.Caption), MB_ICONERROR);
    exit;
  end;
  if not GetCommState(port, @PortInfo) then
  begin      
    ErrorCode := GetLastError();
    ShowMessage('Oops, get COM port state failed!'); 
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, ErrorCode, LANG_NEUTRAL,
      LPSTR(@msg), 1024, nil);
    MessageBoxA(Form1.Handle, LPCSTR(@msg), LPCSTR(Form1.Caption), MB_ICONERROR);
    exit;
  end;
  PortInfo.BaudRate := CBR_1200;
  PortInfo.Parity := NOPARITY;
  PortInfo.ByteSize := 8;
  PortInfo.StopBits := 1;
  if not SetCommState(port, @PortInfo) then
  begin
    ErrorCode := GetLastError();
    ShowMessage('Oops, set COM port state failed!');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, ErrorCode, LANG_NEUTRAL,
      LPSTR(@msg), 1024, nil);
    MessageBoxA(Form1.Handle, LPCSTR(@msg), LPCSTR(Form1.Caption), MB_ICONERROR);
    exit;
  end;
  PurgeComm(port, PURGE_RXCLEAR);
  HoldData.Enabled := true;
end;

procedure TForm1.AboutButtonClick(Sender: TObject);
begin
  MessageBoxA(Form1.Handle, 'Made By 000lbh v0.2'#10'License: GPL v3'#10'Reference: Benzoin96485/Combust', 'About', 64);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  port := -1;
  ExpDataSet.Active := True;
  ExpDataSet.First;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  ExpDataSet.Active := false;
end;

procedure TForm1.HoldDataClick(Sender: TObject);
var
  buf: array[0..100] of byte;
  bytesread: DWORD;
  gotdata: string;
  i: integer;
begin
  PurgeComm(port, PURGE_RXCLEAR);
  for i:=1 to 5 do begin
    if not ReadFile(port, buf, 7, bytesread, nil) then
    begin
      ErrorCode := GetLastError();
      StopTimer;
      ShowMessage('Oops, read failed!');
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, ErrorCode, LANG_NEUTRAL,
        LPSTR(@msg), 1024, nil);
      MessageBoxA(Form1.Handle, LPCSTR(@msg), LPCSTR(Form1.Caption), MB_ICONERROR);
      exit;
    end;
    if buf[0] = 255 then
       break;
    if i = 5 then
    begin
      StopTimer;
      ShowMessage('Oops, got corrupted data!');
      exit;
    end;
  end;
  maccode.Caption := buf[1].ToString();
  case buf[2] of
    11: gotdata := '-0';
    10: gotdata := '+0';
    12: gotdata := '-1';
    1: gotdata := '+1';
    else gotdata := buf[2].ToString();
  end;
  for i:= 3 to 6 do
    gotdata := gotdata + buf[i].ToString();
  OutputArea.Lines.Add(TimeToStr(Time()) + ', ' + gotdata);
  ExpDataSet.AppendRecord([TimeToStr(Time()), gotdata]);
  if AutoSaveCheck.Checked then
    ExpDataSet.SaveFileAs(FileName);
end;

procedure TForm1.HoldIntervalTimer(Sender: TObject);
begin
  HoldDataClick(Sender);
end;

procedure TForm1.SaveClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    FileName := SaveDialog1.FileName;
    ExpDataSet.SaveFileAs(FileName);
    AutoSaveCheck.Enabled := true;
  end;
end;

procedure TForm1.SwitchTimerClick(Sender: TObject);
begin
  if HoldInterval.Enabled then
    StopTimer
  else
    StartTimer;
end;

procedure TForm1.StartTimer;
begin
  HoldInterval.Interval := string(IntervalSet.Caption).ToInteger();
  HoldInterval.Enabled := true;
  SwitchTimer.Caption := 'Stop';
end;

procedure TForm1.StopTimer;
begin
  HoldInterval.Enabled := false;
  SwitchTimer.Caption := 'Start';
end;

end.

