unit CMTMaskEdit;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Mask, Winapi.Messages;

type
  TMaskType = (mtNone, mtCPF, mtCNPJ, mtRG, mtCEP, mtTelefone, mtCelular, mtServerIp);

  TCMTMaskEdit = class(TMaskEdit)
  private
    FMaskType: TMaskType;
    procedure SetMaskType(const Value: TMaskType);
    procedure CMExit(var Message: TMessage); message CM_EXIT;
    function ValidateIP(const AValue: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
  published
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
  inherited Create(AOwner);
  FMaskType := mtNone;
  TextHint := '';
end;

procedure TCMTMaskEdit.SetMaskType(const Value: TMaskType);
begin
  if FMaskType <> Value then
  begin
    FMaskType := Value;
    case FMaskType of
      mtNone:
        begin
          EditMask := '';
          TextHint := '';
        end;
      mtCPF:
        begin
          EditMask := '!999.999.999-99;1;_';
          TextHint := '___.___.___-__';
        end;
      mtCNPJ:
        begin
          EditMask := '!99.999.999/9999-99;1;_';
          TextHint := '__.___.___/____-__';
        end;
      mtRG:
        begin
          EditMask := '!99.999.999-9;1;_';
          TextHint := '__.___.___-__';
        end;
      mtCEP:
        begin
          EditMask := '!99999-999;1;_';
          TextHint := '_____-___';
        end;
      mtTelefone:
        begin
          EditMask := '!(99)9999-9999;1;_';
          TextHint := '(DD)____-____';
        end;
      mtCelular:
        begin
          EditMask := '!(99)99999-9999;1;_';
          TextHint := '(DD)_____-____';
        end;
      mtServerIp:
        begin
          EditMask := ''; // deixa livre, sem máscara rígida
          TextHint := 'Ex: 192.168.0.1';
        end;
    end;
  end;
end;

function TCMTMaskEdit.ValidateIP(const AValue: string): Boolean;
var
  Parts: TArray<string>;
  Num, I: Integer;
begin
  Result := False;
  Parts := AValue.Split(['.']);
  if Length(Parts) <> 4 then
    Exit;

  for I := 0 to 3 do
  begin
    if not TryStrToInt(Parts[I], Num) then
      Exit;
    if (Num < 0) or (Num > 255) then
      Exit;
  end;

  Result := True;
end;

procedure TCMTMaskEdit.CMExit(var Message: TMessage);
begin
  inherited;
  if FMaskType = mtServerIp then
  begin
    if (Text <> '') and (not ValidateIP(Text)) then
    begin
      // Aqui você pode escolher:
      // 1) Mostrar mensagem
      // ShowMessage('IP inválido!');
      // 2) Limpar o campo
      Text := '';
      // 3) Ou até colocar '0.0.0.0'
      // Text := '0.0.0.0';
    end;
  end;
end;

end.
