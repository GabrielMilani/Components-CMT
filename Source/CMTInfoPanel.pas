unit CMTInfoPanel;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics, Vcl.Forms,
  CMTNumericEdit;

type
  TCMTInfoPanel = class(TCustomControl)
  private
    // Controles internos
    FBar: TPanel;
    FTitleLabel: TLabel;
    FValueEdit: TCMTNumericEdit;

    // Fonts próprias (seguras para design-time)
    FTitleFont: TFont;
    FValueFont: TFont;

    // Valor lógico (AGORA Currency)
    FValue: Currency;

    // Aparência
    FBarColor: TColor;
    FBackgroundColor: TColor;
    FBarWidth: Integer;

    // Constantes de layout
    const
      TITLE_TOP_PADDING = 8;
      TITLE_HEIGHT      = 18;
      BOTTOM_PADDING    = 8;

    // Métodos internos
    procedure AjustarAlturaValor;

    procedure SetTitleFont(Value: TFont);
    procedure SetValueFont(Value: TFont);

    procedure SetBarColor(const Value: TColor);
    procedure SetBackgroundColor(const Value: TColor);
    procedure SetBarWidth(const Value: Integer);

    procedure SetTitle(const Value: string);
    procedure SetValue(const Value: Currency);

    function GetTitle: string;
    function GetValue: Currency;

  protected
    procedure Resize; override;
    procedure Loaded; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    // Padrões VCL
    property Align;
    property Anchors;
    property Enabled;
    property Visible;

    property Width  default 300;
    property Height default 70;

    // Conteúdo
    property Title: string read GetTitle write SetTitle;
    property Value: Currency read GetValue write SetValue; // <<< MANTÉM O NOME

    // Visual
    property BarColor: TColor read FBarColor write SetBarColor default clRed;
    property BarWidth: Integer read FBarWidth write SetBarWidth default 5;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor;

    // Fontes (Object Inspector)
    property TitleFont: TFont read FTitleFont write SetTitleFont;
    property ValueFont: TFont read FValueFont write SetValueFont;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTInfoPanel]);
end;

{ TCMTInfoPanel }

constructor TCMTInfoPanel.Create(AOwner: TComponent);
begin
  inherited;

  Width  := 300;
  Height := 70;

  ParentBackground := False;
  Color := $00F2F2F2;
  FBackgroundColor := Color;

  FBarColor := clRed;
  FBarWidth := 5;

  // === Fonts próprias (ESSENCIAL) ===
  FTitleFont := TFont.Create;
  FValueFont := TFont.Create;

  FTitleFont.Name  := 'Segoe UI';
  FTitleFont.Size  := 9;
  FTitleFont.Color := clGray;

  FValueFont.Name  := 'Segoe UI';
  FValueFont.Size  := 20;
  FValueFont.Style := [fsBold];
  FValueFont.Color := clRed;

  // Valor inicial
  FValue := 0;

  // === Barra lateral ===
  FBar := TPanel.Create(Self);
  FBar.Parent := Self;
  FBar.Align  := alLeft;
  FBar.Width  := FBarWidth;
  FBar.BevelOuter := bvNone;
  FBar.Color := FBarColor;

  // === Título ===
  FTitleLabel := TLabel.Create(Self);
  FTitleLabel.Parent := Self;
  FTitleLabel.Caption := 'TÍTULO';
  FTitleLabel.Transparent := True;
  FTitleLabel.Font.Assign(FTitleFont);

  // === Valor (TCMTNumericEdit) ===
  FValueEdit := TCMTNumericEdit.Create(Self);
  FValueEdit.Parent := Self;
  FValueEdit.BorderStyle := bsNone;
  FValueEdit.ReadOnly := True;
  FValueEdit.TabStop := False;
  FValueEdit.Cursor := crArrow;
  FValueEdit.Alignment := taRightJustify;
  FValueEdit.Color := Color;
  FValueEdit.Font.Assign(FValueFont);
  FValueEdit.Value := FValue;
end;

destructor TCMTInfoPanel.Destroy;
begin
  FTitleFont.Free;
  FValueFont.Free;
  inherited;
end;

procedure TCMTInfoPanel.Loaded;
begin
  inherited;
  FTitleLabel.Font.Assign(FTitleFont);
  FValueEdit.Font.Assign(FValueFont);
  FValueEdit.Value := FValue;
  Resize;
end;

procedure TCMTInfoPanel.Resize;
begin
  inherited;

  // Título sempre no topo
  FTitleLabel.Left := FBarWidth + 10;
  FTitleLabel.Top  := TITLE_TOP_PADDING;

  // Valor alinhado à direita
  FValueEdit.Width := Width - FBarWidth - 20;
  FValueEdit.Left  := Width - FValueEdit.Width - 10;

  AjustarAlturaValor;
end;

procedure TCMTInfoPanel.AjustarAlturaValor;
var
  TextHeight, AreaDisponivel, ValorTop: Integer;
begin
  Canvas.Font.Assign(FValueFont);

  TextHeight := Canvas.TextHeight('Hg');
  FValueEdit.Height := TextHeight + 6;

  AreaDisponivel :=
    Height -
    (TITLE_TOP_PADDING + TITLE_HEIGHT) -
    BOTTOM_PADDING;

  ValorTop :=
    TITLE_TOP_PADDING +
    TITLE_HEIGHT +
    (AreaDisponivel - FValueEdit.Height) div 2;

  if ValorTop < TITLE_TOP_PADDING + TITLE_HEIGHT then
    ValorTop := TITLE_TOP_PADDING + TITLE_HEIGHT;

  FValueEdit.Top := ValorTop;
end;

procedure TCMTInfoPanel.SetTitleFont(Value: TFont);
begin
  FTitleFont.Assign(Value);
  if Assigned(FTitleLabel) then
    FTitleLabel.Font.Assign(FTitleFont);
end;

procedure TCMTInfoPanel.SetValueFont(Value: TFont);
begin
  FValueFont.Assign(Value);
  if Assigned(FValueEdit) then
  begin
    FValueEdit.Font.Assign(FValueFont);
    AjustarAlturaValor;
  end;
end;

procedure TCMTInfoPanel.SetBarColor(const Value: TColor);
begin
  FBarColor := Value;
  FBar.Color := Value;
end;

procedure TCMTInfoPanel.SetBackgroundColor(const Value: TColor);
begin
  FBackgroundColor := Value;
  Color := Value;
  FValueEdit.Color := Value;
end;

procedure TCMTInfoPanel.SetBarWidth(const Value: Integer);
begin
  FBarWidth := Value;
  FBar.Width := Value;
  Resize;
end;

procedure TCMTInfoPanel.SetTitle(const Value: string);
begin
  FTitleLabel.Caption := Value;
end;

procedure TCMTInfoPanel.SetValue(const Value: Currency);
begin
  FValue := Value;
  if Assigned(FValueEdit) then
    FValueEdit.Value := Value;
end;

function TCMTInfoPanel.GetTitle: string;
begin
  Result := FTitleLabel.Caption;
end;

function TCMTInfoPanel.GetValue: Currency;
begin
  Result := FValue;
end;

end.
