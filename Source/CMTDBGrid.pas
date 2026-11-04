unit CMTDBGrid;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Vcl.DBGrids,
  Winapi.Windows, Winapi.Messages, Vcl.Forms, Vcl.Graphics, Data.DB, Math,
  System.Generics.Collections;

const
  WM_CMT_AJUSTAR_COLUNAS = WM_USER + 101;

type
  // Entrada da regra de largura: o que a coluna precisa para nao cortar o texto,
  // se ela e a preferida para receber a sobra e se o usuario fixou a largura.
  TCMTColunaAjuste = record
    Necessaria: Integer;
    Flexivel: Boolean;
    Travada: Boolean;
  end;

  TCMTDBGrid = class(TDBGrid)
  private
    FAutoSizeColumns: Boolean;
    FAutoFitColumns: Boolean;
    FAjustePendente: Boolean;
    FAplicandoLarguras: Boolean;
    FMedidas: TDictionary<TColumn, Integer>;
    FLargurasAplicadas: TDictionary<TColumn, Integer>;
    FColunasTravadas: TDictionary<TColumn, Boolean>;
    FFixedColumnNames: TStrings;
    FFlexColumnNames: TStrings;
    procedure SetAutoSizeColumns(const Value: Boolean);
    procedure AdjustColumnWidths;
    procedure SetAutoFitColumns(const Value: Boolean);
    procedure LimparAjuste;
    function LarguraDisponivel: Integer;
    function MedirColunas: Boolean;
    procedure AplicarLarguras;
    procedure ExecutarAplicacaoLarguras;
    procedure WMAjustarColunas(var AMensagem: TMessage); message WM_CMT_AJUSTAR_COLUNAS;
  protected
    procedure DrawColumnCell(const Rect: TRect; DataCol: Integer;
      Column: TColumn; State: TGridDrawState); override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure Paint; override;
    procedure LinkActive(Value: Boolean); override;
    procedure ColWidthsChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor destroy; override;
    // Descarta as medidas e larguras manuais e mede de novo as linhas visiveis.
    // Chamar depois de recarregar os dados com o dataset ja aberto; sem isso as
    // colunas so alargam ate o dataset ser reaberto.
    procedure ReiniciarAjusteColunas;
  published
    property AutoSizeColumns: Boolean read FAutoSizeColumns write SetAutoSizeColumns default False;
    // Colunas na medida do texto das linhas visiveis: a sobra estica ate a borda
    // e, quando falta espaco, nada e cortado e a barra horizontal aparece.
    property AutoFitColumns: Boolean read FAutoFitColumns write SetAutoFitColumns default False;
    property FixedColumnNames: TStrings read FFixedColumnNames write FFixedColumnNames;
    property FlexColumnNames: TStrings read FFlexColumnNames write FFlexColumnNames;
  end;

// Regra pura do AutoFitColumns: cada coluna recebe o necessario e a sobra vai para as
// flexiveis nao travadas (sem nenhuma, para todas as nao travadas), proporcionalmente.
function CalcularLargurasColunas(const AColunas: TArray<TCMTColunaAjuste>;
  const ADisponivel: Integer): TArray<Integer>;

procedure Register;

implementation

const
  MARGEM_TEXTO_COLUNA = 10;
  FOLGA_BORDA_GRID = 2;

function CalcularLargurasColunas(const AColunas: TArray<TCMTColunaAjuste>;
  const ADisponivel: Integer): TArray<Integer>;
var
  vIndice, vSoma, vSobra, vPesoTotal, vQuantidadeReceptoras: Integer;
  vPesoAcumulado, vEntregue, vParte: Integer;
  vTemFlexivel: Boolean;

  function Recebe(const AColuna: TCMTColunaAjuste): Boolean;
  begin
    Result := (not AColuna.Travada) and (AColuna.Flexivel or not vTemFlexivel);
  end;

begin
  SetLength(Result, Length(AColunas));
  vSoma := 0;
  vTemFlexivel := False;
  for vIndice := 0 to High(AColunas) do
  begin
    Result[vIndice] := AColunas[vIndice].Necessaria;
    Inc(vSoma, AColunas[vIndice].Necessaria);
    if AColunas[vIndice].Flexivel and not AColunas[vIndice].Travada then
      vTemFlexivel := True;
  end;

  vSobra := ADisponivel - vSoma;
  if vSobra <= 0 then
    Exit;

  vPesoTotal := 0;
  vQuantidadeReceptoras := 0;
  for vIndice := 0 to High(AColunas) do
    if Recebe(AColunas[vIndice]) then
    begin
      Inc(vPesoTotal, AColunas[vIndice].Necessaria);
      Inc(vQuantidadeReceptoras);
    end;

  if vQuantidadeReceptoras = 0 then
    Exit;

  // Acumulado: o arredondamento nao se perde e a soma fecha exata.
  // Receptoras todas sem medida dividem em partes iguais.
  vPesoAcumulado := 0;
  vEntregue := 0;
  for vIndice := 0 to High(AColunas) do
    if Recebe(AColunas[vIndice]) then
    begin
      if vPesoTotal > 0 then
      begin
        Inc(vPesoAcumulado, AColunas[vIndice].Necessaria);
        vParte := Trunc(Int64(vSobra) * vPesoAcumulado / vPesoTotal);
      end
      else
      begin
        Inc(vPesoAcumulado);
        vParte := Trunc(Int64(vSobra) * vPesoAcumulado / vQuantidadeReceptoras);
      end;
      Inc(Result[vIndice], vParte - vEntregue);
      vEntregue := vParte;
    end;
end;

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
  FMedidas := TDictionary<TColumn, Integer>.Create;
  FLargurasAplicadas := TDictionary<TColumn, Integer>.Create;
  FColunasTravadas := TDictionary<TColumn, Boolean>.Create;
end;

destructor TCMTDBGrid.destroy;
begin
  FFixedColumnNames.Free;
  FFlexColumnNames.Free;
  inherited;
  // Depois do inherited: fechar o vinculo com os dados ainda passa pelo LinkActive
  FMedidas.Free;
  FLargurasAplicadas.Free;
  FColunasTravadas.Free;
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
  if FAutoFitColumns then Exit;
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

procedure TCMTDBGrid.SetAutoFitColumns(const Value: Boolean);
begin
  if FAutoFitColumns <> Value then
  begin
    FAutoFitColumns := Value;
    LimparAjuste;
    if FAutoFitColumns then
      ReiniciarAjusteColunas
    else if FAutoSizeColumns then
      AdjustColumnWidths;
  end;
end;

procedure TCMTDBGrid.LimparAjuste;
begin
  FMedidas.Clear;
  FLargurasAplicadas.Clear;
  FColunasTravadas.Clear;
end;

function TCMTDBGrid.LarguraDisponivel: Integer;
var
  vEspessuraLinha: Integer;
  vIndice: Integer;
begin
  if dgColLines in Options then
    vEspessuraLinha := GridLineWidth
  else
    vEspessuraLinha := 0;

  Result := ClientWidth - FOLGA_BORDA_GRID;
  if dgIndicator in Options then
    Dec(Result, ColWidths[0] + vEspessuraLinha);
  for vIndice := 0 to Columns.Count - 1 do
    if Columns[vIndice].Visible then
      Dec(Result, vEspessuraLinha);
end;

// So le as linhas que ja estao no buffer do grid: o cursor do dataset nao anda, os
// eventos de rolagem nao disparam e o custo nao depende do total de registros.
function TCMTDBGrid.MedirColunas: Boolean;
var
  vMaiores: TArray<Integer>;
  vIndice, vLinha, vRegistroAtivo, vMargem, vMedidaAtual: Integer;
  vColuna: TColumn;
begin
  Result := False;
  if (csDesigning in ComponentState) or (csDestroying in ComponentState) or
    (not HandleAllocated) or (not DataLink.Active) or (Columns.Count = 0) or
    DataLink.DataSet.ControlsDisabled then
    Exit;

  vMargem := ScaleValue(MARGEM_TEXTO_COLUNA);
  SetLength(vMaiores, Columns.Count);

  for vIndice := 0 to Columns.Count - 1 do
  begin
    vColuna := Columns[vIndice];
    if vColuna.Visible and not FColunasTravadas.ContainsKey(vColuna) then
    begin
      Canvas.Font.Assign(vColuna.Title.Font);
      vMaiores[vIndice] := Canvas.TextWidth(vColuna.Title.Caption);
    end;
  end;

  vRegistroAtivo := DataLink.ActiveRecord;
  try
    for vLinha := 0 to DataLink.RecordCount - 1 do
    begin
      DataLink.ActiveRecord := vLinha;
      for vIndice := 0 to Columns.Count - 1 do
      begin
        vColuna := Columns[vIndice];
        if vColuna.Visible and (vColuna.Field <> nil) and
          not FColunasTravadas.ContainsKey(vColuna) then
        begin
          Canvas.Font.Assign(vColuna.Font);
          vMaiores[vIndice] := Max(vMaiores[vIndice], Canvas.TextWidth(vColuna.Field.DisplayText));
        end;
      end;
    end;
  finally
    DataLink.ActiveRecord := vRegistroAtivo;
  end;

  // Entre recargas a medida so cresce: rolar a grade nao faz a coluna encolher
  for vIndice := 0 to Columns.Count - 1 do
  begin
    vColuna := Columns[vIndice];
    if vColuna.Visible and not FColunasTravadas.ContainsKey(vColuna) then
    begin
      if (not FMedidas.TryGetValue(vColuna, vMedidaAtual)) or
        (vMaiores[vIndice] + vMargem > vMedidaAtual) then
      begin
        FMedidas.AddOrSetValue(vColuna, vMaiores[vIndice] + vMargem);
        Result := True;
      end;
    end;
  end;
end;

procedure TCMTDBGrid.ExecutarAplicacaoLarguras;
var
  vColunas: TArray<TCMTColunaAjuste>;
  vVisiveis: TArray<TColumn>;
  vLarguras: TArray<Integer>;
  vIndice, vQuantidade, vMedida: Integer;
  vColuna: TColumn;
  vMudou: Boolean;
begin
  SetLength(vColunas, Columns.Count);
  SetLength(vVisiveis, Columns.Count);
  vQuantidade := 0;
  for vIndice := 0 to Columns.Count - 1 do
  begin
    vColuna := Columns[vIndice];
    if not vColuna.Visible then
      Continue;
    vColunas[vQuantidade].Travada := FColunasTravadas.ContainsKey(vColuna);
    vColunas[vQuantidade].Flexivel := FFlexColumnNames.IndexOf(vColuna.FieldName) >= 0;
    if vColunas[vQuantidade].Travada or not FMedidas.TryGetValue(vColuna, vMedida) then
      vMedida := vColuna.Width;
    vColunas[vQuantidade].Necessaria := vMedida;
    vVisiveis[vQuantidade] := vColuna;
    Inc(vQuantidade);
  end;
  SetLength(vColunas, vQuantidade);

  vLarguras := CalcularLargurasColunas(vColunas, LarguraDisponivel);

  vMudou := False;
  for vIndice := 0 to vQuantidade - 1 do
    if vVisiveis[vIndice].Width <> vLarguras[vIndice] then
      vMudou := True;

  if vMudou then
  begin
    BeginLayout;
    try
      for vIndice := 0 to vQuantidade - 1 do
        vVisiveis[vIndice].Width := vLarguras[vIndice];
    finally
      EndLayout;
    end;
  end;

  for vIndice := 0 to vQuantidade - 1 do
    FLargurasAplicadas.AddOrSetValue(vVisiveis[vIndice], vLarguras[vIndice]);
end;

procedure TCMTDBGrid.AplicarLarguras;
var
  vTentativa, vLarguraCliente: Integer;
begin
  if FAplicandoLarguras or (csDesigning in ComponentState) or (csLoading in ComponentState) or
    (csDestroying in ComponentState) or (not HandleAllocated) or (not DataLink.Active) or
    (Columns.Count = 0) then
    Exit;

  FAplicandoLarguras := True;
  try
    // Mudar as colunas pode mostrar ou esconder uma barra e alterar a area util
    for vTentativa := 1 to 2 do
    begin
      vLarguraCliente := ClientWidth;
      ExecutarAplicacaoLarguras;
      if ClientWidth = vLarguraCliente then
        Break;
    end;
  finally
    FAplicandoLarguras := False;
  end;
end;

procedure TCMTDBGrid.ReiniciarAjusteColunas;
begin
  if not FAutoFitColumns then
    Exit;
  LimparAjuste;
  MedirColunas;
  AplicarLarguras;
end;

procedure TCMTDBGrid.WMAjustarColunas(var AMensagem: TMessage);
begin
  FAjustePendente := False;
  if FAutoFitColumns then
    AplicarLarguras;
end;

procedure TCMTDBGrid.Paint;
begin
  // Alterar colunas durante a pintura invalida a propria pintura: aplica depois dela
  if FAutoFitColumns and (not FAjustePendente) and (not FAplicandoLarguras) and MedirColunas then
  begin
    FAjustePendente := True;
    PostMessage(Handle, WM_CMT_AJUSTAR_COLUNAS, 0, 0);
  end;
  inherited;
end;

procedure TCMTDBGrid.LinkActive(Value: Boolean);
begin
  // As colunas podem ser recriadas junto com o vinculo
  if FAutoFitColumns then
    LimparAjuste;
  inherited;
end;

procedure TCMTDBGrid.ColWidthsChanged;
var
  vIndice, vAplicada: Integer;
  vColuna: TColumn;
begin
  inherited;
  if (not FAutoFitColumns) or (GridState <> gsColSizing) then
    Exit;

  // Coluna arrastada pelo usuario fica como ele deixou ate o proximo reinicio
  for vIndice := 0 to Columns.Count - 1 do
  begin
    vColuna := Columns[vIndice];
    if FLargurasAplicadas.TryGetValue(vColuna, vAplicada) and (vColuna.Width <> vAplicada) then
      FColunasTravadas.AddOrSetValue(vColuna, True);
  end;

  if HandleAllocated and not FAjustePendente then
  begin
    FAjustePendente := True;
    PostMessage(Handle, WM_CMT_AJUSTAR_COLUNAS, 0, 0);
  end;
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
  if FAutoFitColumns then
    AplicarLarguras
  else if FAutoSizeColumns then
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
