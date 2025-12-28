unit CMTDBGrid;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Vcl.DBGrids,
  Winapi.Windows, Vcl.Forms, Vcl.Graphics, Data.DB, Math;

type
  TCMTDBGrid = class(TDBGrid)
  private
    FAutoSizeColumns: Boolean;
    FFixedColumnNames: TStrings;
    FFlexColumnNames: TStrings;
    procedure SetAutoSizeColumns(const Value: Boolean);
    procedure AdjustColumnWidths;
  protected
    procedure DrawColumnCell(const Rect: TRect; DataCol: Integer;
      Column: TColumn; State: TGridDrawState); override;
    procedure Loaded; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor destroy; override;
  published
    property AutoSizeColumns: Boolean read FAutoSizeColumns write SetAutoSizeColumns default False;
    property FixedColumnNames: TStrings read FFixedColumnNames write FFixedColumnNames;
    property FlexColumnNames: TStrings read FFlexColumnNames write FFlexColumnNames;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTDBGrid]);
end;

constructor TCMTDBGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFixedColumnNames := TStringList.Create;
  FFlexColumnNames := TStringList.Create;
  // Estilo visual
  BorderStyle := bsNone;
  DrawingStyle := gdsClassic;

  // Fonte padrão
  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Style := [fsBold];

  // Título das colunas
  TitleFont.Name := 'Segoe UI';
  TitleFont.Size := 9;
  TitleFont.Style := [fsBold];
  TitleFont.Color := clWhite;

  // Cor de fundo fixa (convertido de $00676767)
  FixedColor := TColor($00676767);

  // Opções do grid
  Options := [
    dgTitles,
    dgColumnResize,
    dgColLines,
    dgTabs,
    dgRowSelect,
    dgAlwaysShowSelection,
    dgConfirmDelete,
    dgCancelOnExit,
    dgTitleClick,
    dgTitleHotTrack
  ];

  // Estilo visual adicional
  Ctl3D := False;
  ParentCtl3D := False;
  GridLineWidth := 1;
  Color := clWhite;

  FAutoSizeColumns := False;
end;

destructor TCMTDBGrid.destroy;
begin
  FFixedColumnNames.Free;
  FFlexColumnNames.Free;
  inherited;
end;

procedure TCMTDBGrid.SetAutoSizeColumns(const Value: Boolean);
begin
  if FAutoSizeColumns <> Value then
  begin
    FAutoSizeColumns := Value;
    if FAutoSizeColumns then
      AdjustColumnWidths;
  end;
end;

procedure TCMTDBGrid.AdjustColumnWidths;
var
  i: Integer;
  FixedWidth, FlexCount, AvailableWidth, EachFlexWidth: Integer;
begin
  if Columns.Count = 0 then Exit;

  FixedWidth := 0;
  FlexCount := 0;

  // Soma larguras fixas e conta flexíveis
  for i := 0 to Columns.Count - 1 do
  begin
    if FFixedColumnNames.IndexOf(Columns[i].FieldName) >= 0 then
      Inc(FixedWidth, Columns[i].Width)
    else if FFlexColumnNames.IndexOf(Columns[i].FieldName) >= 0 then
      Inc(FlexCount);
  end;

  if FlexCount = 0 then Exit;

  AvailableWidth := ClientWidth - FixedWidth - 2;

  if dgColLines in Options then
    Dec(AvailableWidth, GridLineWidth * Columns.Count);

  if AvailableWidth <= 0 then Exit;

  EachFlexWidth := AvailableWidth div FlexCount;

  // Aplica somente nas colunas flexíveis
  for i := 0 to Columns.Count - 1 do
    if FFlexColumnNames.IndexOf(Columns[i].FieldName) >= 0 then
      Columns[i].Width := EachFlexWidth;
end;

procedure TCMTDBGrid.Loaded;
begin
  inherited;
  if FAutoSizeColumns then
    AdjustColumnWidths;
end;

procedure TCMTDBGrid.Resize;
begin
  inherited;
  if FAutoSizeColumns then
    AdjustColumnWidths;
end;

procedure TCMTDBGrid.DrawColumnCell(const Rect: TRect; DataCol: Integer;
  Column: TColumn; State: TGridDrawState);
var
  RecNo: Integer;
begin
  inherited;
  if Assigned(DataSource) and Assigned(DataSource.DataSet) then
    RecNo := DataSource.DataSet.RecNo
  else
    RecNo := 0;

  // Alternância de cor de fundo
  if Odd(RecNo) then
    Canvas.Brush.Color := $00E9E9E9
  else
    Canvas.Brush.Color := clWhite;

  // Estilo de seleção
  if gdSelected in State then
  begin
    Canvas.Brush.Color := clSkyBlue;
    Canvas.Font.Color := clWhite;
    Canvas.Font.Style := [fsBold];
  end
  else
  begin
    Canvas.Font.Color := Font.Color;
    Canvas.Font.Style := Font.Style;
  end;

  // Desenho da célula
  Canvas.FillRect(Rect);
  DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

end.
