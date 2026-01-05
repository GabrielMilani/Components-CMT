unit CMTNumericEdit;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.StdCtrls,
  Winapi.Windows;

type
  TCMTNumericEdit = class(TEdit)
  private
    FDecimals: Integer;
    FDisplayFormat: string;
    FAllowNegative: Boolean;

    function Normalizar(const S: string): string;
    function GetValue: Double;
    procedure SetValue(const AValue: Double);
    procedure SetDecimals(const AValue: Integer);
    procedure AtualizarDisplayFormat;
  protected
    procedure KeyPress(var Key: Char); override;
    procedure DoExit; override;
    procedure DoEnter; override;
  public
    constructor Create(AOwner: TComponent); override;

    property Value: Double read GetValue write SetValue;
  published
    property Decimals: Integer read FDecimals write SetDecimals default 2;
    property DisplayFormat: string read FDisplayFormat write FDisplayFormat;
    property AllowNegative: Boolean read FAllowNegative write FAllowNegative default False;
  end;

procedure Register;

implementation

{ TCMTNumericEdit }

constructor TCMTNumericEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDecimals := 2;
  FAllowNegative := False;

  AtualizarDisplayFormat;
end;

procedure TCMTNumericEdit.KeyPress(var Key: Char);
var
  Texto: string;
begin
  inherited;

  if Key = #8 then Exit;

  if CharInSet(Key, ['0'..'9']) then Exit;

  if (Key = '-') and FAllowNegative then
  begin
    if (SelStart = 0) and (Pos('-', Text) = 0) then Exit;
    Key := #0;
    Exit;
  end;

  if CharInSet(Key, [',', '.']) then
  begin
    Texto := Text;
    if (Pos(',', Texto) > 0) or (Pos('.', Texto) > 0) then
      Key := #0;
    Exit;
  end;

  Key := #0;
end;

procedure TCMTNumericEdit.DoEnter;
begin
  inherited;

  if Abs(GetValue) < 0.0000001 then
    Text := '';
end;

procedure TCMTNumericEdit.DoExit;
begin
  inherited;

  if Trim(Text) = '' then
    Text := FormatFloat(FDisplayFormat, 0)
  else
    Text := FormatFloat(FDisplayFormat, Value);
end;

function TCMTNumericEdit.Normalizar(const S: string): string;
begin
  Result := Trim(S);
  Result := StringReplace(Result, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
  Result := StringReplace(Result, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
end;

function TCMTNumericEdit.GetValue: Double;
begin
  Result := StrToFloatDef(Normalizar(Text), 0);
end;

procedure TCMTNumericEdit.SetValue(const AValue: Double);
begin
  Text := FormatFloat(FDisplayFormat, AValue);
end;

procedure TCMTNumericEdit.SetDecimals(const AValue: Integer);
begin
  if AValue < 0 then
    FDecimals := 0
  else
    FDecimals := AValue;

  AtualizarDisplayFormat;
end;

procedure TCMTNumericEdit.AtualizarDisplayFormat;
begin
  if Trim(FDisplayFormat) = '' then
    FDisplayFormat := '#,##0.' + StringOfChar('0', FDecimals);
end;

procedure Register;
begin
  RegisterComponents('CMT', [TCMTNumericEdit]);
end;

end.
