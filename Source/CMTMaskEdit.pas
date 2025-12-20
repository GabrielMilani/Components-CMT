unit CMTMaskEdit;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Mask, Winapi.Messages;

type
  TMaskType = (mtNone, mtCPF, mtCNPJ, mtRG, mtCEP, mtTelefone, mtCelular, mtServerIp);

  TCMTMaskEdit = class(TMaskEdit)
  private
    FMaskType: TMaskType;

    function OnlyNumbers(const AValue: string): string;
    function FormatCPF(const AValue: string): string;
    function FormatCNPJ(const AValue: string): string;
    function FormatRG(const AValue: string): string;
    function FormatCEP(const AValue: string): string;
    function FormatTelefone(const AValue: string): string;
    function FormatCelular(const AValue: string): string;

    function GetUnmaskedText: string;
    function GetText: string;

    procedure SetMaskType(const Value: TMaskType);
    procedure SetText(const Value: string);

    procedure CMExit(var Message: TMessage); message CM_EXIT;
    function ValidateIP(const AValue: string): Boolean;

  public
    constructor Create(AOwner: TComponent); override;

    property UnmaskedText: string read GetUnmaskedText;

  published
    property Text: string read GetText write SetText;
    property MaskType: TMaskType read FMaskType write SetMaskType;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTMaskEdit]);
end;

constructor TCMTMaskEdit.Create(AOwner: TComponent);
begin
  inherited;
  FMaskType := mtNone;
end;

{ UTIL }
function TCMTMaskEdit.OnlyNumbers(const AValue: string): string;
var c: Char;
begin
  Result := '';
  for c in AValue do
    if c in ['0'..'9'] then
      Result := Result + c;
end;

function TCMTMaskEdit.GetText: string;
begin
  Result := inherited Text; // <<< AQUI ESTÁ A CORREÇÃO QUE FALTAVA
end;

function TCMTMaskEdit.GetUnmaskedText: string;
begin
  Result := OnlyNumbers(inherited Text);
end;

{ FORMATADORES }
function TCMTMaskEdit.FormatCPF(const AValue: string): string;
var s: string;
begin
  s := OnlyNumbers(AValue);
  if Length(s) = 11 then
    Result := Copy(s,1,3)+'.'+Copy(s,4,3)+'.'+Copy(s,7,3)+'-'+Copy(s,10,2)
  else
    Result := AValue;
end;

function TCMTMaskEdit.FormatCNPJ(const AValue: string): string;
var s: string;
begin
  s := OnlyNumbers(AValue);
  if Length(s) = 14 then
    Result := Copy(s,1,2)+'.'+Copy(s,3,3)+'.'+Copy(s,6,3)+'/'+Copy(s,9,4)+'-'+Copy(s,13,2)
  else
    Result := AValue;
end;

function TCMTMaskEdit.FormatRG(const AValue: string): string;
var s: string;
begin
  s := OnlyNumbers(AValue);
  if Length(s) = 9 then
    Result := Copy(s,1,2)+'.'+Copy(s,3,3)+'.'+Copy(s,6,3)+'-'+Copy(s,9,1)
  else
    Result := AValue;
end;

function TCMTMaskEdit.FormatCEP(const AValue: string): string;
var s: string;
begin
  s := OnlyNumbers(AValue);
  if Length(s) = 8 then
    Result := Copy(s,1,5)+'-'+Copy(s,6,3)
  else
    Result := AValue;
end;

function TCMTMaskEdit.FormatTelefone(const AValue: string): string;
var s: string;
begin
  s := OnlyNumbers(AValue);
  if Length(s) = 10 then
    Result := '('+Copy(s,1,2)+')'+Copy(s,3,4)+'-'+Copy(s,7,4)
  else
    Result := AValue;
end;

function TCMTMaskEdit.FormatCelular(const AValue: string): string;
var s: string;
begin
  s := OnlyNumbers(AValue);
  if Length(s) = 11 then
    Result := '('+Copy(s,1,2)+')'+Copy(s,3,5)+'-'+Copy(s,8,4)
  else
    Result := AValue;
end;

{ MÁSCARA }
procedure TCMTMaskEdit.SetMaskType(const Value: TMaskType);
begin
  FMaskType := Value;

  case Value of
    mtNone:
      EditMask := '';

    mtCPF:
      EditMask := '!999.999.999-99;1;_';

    mtCNPJ:
      EditMask := '!99.999.999/9999-99;1;_';

    mtRG:
      EditMask := '!99.999.999-9;1;_';

    mtCEP:
      EditMask := '!99999-999;1;_';

    mtTelefone:
      EditMask := '!(99)9999-9999;1;_';

    mtCelular:
      EditMask := '!(99)99999-9999;1;_';

    mtServerIp:
      EditMask := '';
  end;
end;

{ SETTEXT }
procedure TCMTMaskEdit.SetText(const Value: string);
var raw: string;
begin
  raw := OnlyNumbers(Value);

  case FMaskType of
    mtCPF:      inherited Text := FormatCPF(raw);
    mtCNPJ:     inherited Text := FormatCNPJ(raw);
    mtRG:       inherited Text := FormatRG(raw);
    mtCEP:      inherited Text := FormatCEP(raw);
    mtTelefone: inherited Text := FormatTelefone(raw);
    mtCelular:  inherited Text := FormatCelular(raw);
    mtServerIp: inherited Text := Value;
  else
    inherited Text := Value;
  end;
end;

{ IP }
function TCMTMaskEdit.ValidateIP(const AValue: string): Boolean;
var p: TArray<string>; n,i: Integer;
begin
  p := AValue.Split(['.']);
  if Length(p) <> 4 then exit(False);

  for i := 0 to 3 do
    if (not TryStrToInt(p[i],n)) or (n < 0) or (n > 255) then
      exit(False);

  Result := True;
end;

procedure TCMTMaskEdit.CMExit(var Message: TMessage);
begin
  inherited;
  if (FMaskType = mtServerIp) and (Text <> '') then
    if not ValidateIP(Text) then
      inherited Text := '';
end;

end.
