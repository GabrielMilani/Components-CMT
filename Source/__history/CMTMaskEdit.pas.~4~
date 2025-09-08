unit CMTMaskEdit;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Mask;

type
  // Tipos de máscara que estarão disponíveis para seleção
  TMaskType = (mtNone, mtCPF, mtCNPJ, mtRG, mtCEP, mtTelefone, mtCelular);


  TCMTMaskEdit = class(TMaskEdit)
  private
    FMaskType: TMaskType;
    procedure SetMaskType(const Value: TMaskType);
  public
    constructor Create(AOwner: TComponent); override;
  published
    // A nova propriedade que irá aparecer no Object Inspector
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
  // A propriedade TextHint é muito útil para guiar o usuário
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
    end;
  end;
end;

end.
