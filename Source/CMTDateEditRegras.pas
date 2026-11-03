unit CMTDateEditRegras;

// Regras do TCMTDateEdit sem dependencia de tela: leitura estrita do texto da
// mascara 99/99/9999 e calculo da sugestao de data durante a digitacao.

interface

// Sempre dd/mm/aaaa, sem depender da configuracao regional.
function FormatarData(const AData: TDateTime): string;

// Aceita somente dd/mm/aaaa completo e existente no calendario.
function TryTextoParaData(const ATexto: string; out AData: TDateTime): Boolean;

// Verdadeiro quando o texto da mascara nao tem nenhum digito.
function TextoDataVazio(const ATexto: string): Boolean;

// Digitos a partir do inicio do texto da mascara. Vazio se houver digito depois de um buraco.
function DigitosIniciais(const ATexto: string): string;

// Data completa sugerida para os digitos ja escritos, ou vazio se nao houver sugestao.
// Dia e mes ja completos ficam como foram escritos e o restante vem de hoje; o grupo em
// andamento so sugere se o que foi escrito dele for igual ao de hoje.
function SugerirData(const ADigitos: string; const AHoje: TDateTime): string;

// Data em que o calendario abre: a do campo, ou hoje se o campo estiver vazio.
function DataInicialCalendario(const AData, AHoje: TDateTime): TDateTime;

// Primeira data da grade do mes de AData, comecando no domingo.
function PrimeiraDataDaGrade(const AData: TDateTime): TDateTime;

function NomeMesAno(const AData: TDateTime): string;

// Nome curto do mes (1 a 12), para a grade de meses do calendario.
function NomeMesCurto(const AMes: Integer): string;

// Primeiro ano da pagina de 12 anos que contem AAno.
function PrimeiroAnoDaPagina(const AAno: Integer): Integer;

// Posicao no texto da mascara (a partir de zero) logo depois de N digitos, ja pulando a barra.
function PosicaoAposDigitos(const AQuantidade: Integer): Integer;

implementation

uses
  System.SysUtils;

const
  TAMANHO_TEXTO_DATA = 10;
  QUANTIDADE_DIGITOS_DATA = 8;
  POSICAO_BARRA_DIA = 3;
  POSICAO_BARRA_MES = 6;
  ANOS_POR_PAGINA = 12;

function EhDigito(const ACaractere: Char): Boolean;
begin
  Result := CharInSet(ACaractere, ['0'..'9']);
end;

function FormatarData(const AData: TDateTime): string;
var
  vAno, vMes, vDia: Word;
begin
  DecodeDate(AData, vAno, vMes, vDia);
  Result := Format('%.2d/%.2d/%.4d', [vDia, vMes, vAno]);
end;

function TryTextoParaData(const ATexto: string; out AData: TDateTime): Boolean;
var
  vPosicao: Integer;
begin
  AData := 0;
  Result := False;

  if Length(ATexto) <> TAMANHO_TEXTO_DATA then
    Exit;

  for vPosicao := 1 to TAMANHO_TEXTO_DATA do
    if (vPosicao <> POSICAO_BARRA_DIA) and (vPosicao <> POSICAO_BARRA_MES) and
      not EhDigito(ATexto[vPosicao]) then
      Exit;

  Result := TryEncodeDate(StrToInt(Copy(ATexto, 7, 4)), StrToInt(Copy(ATexto, 4, 2)),
    StrToInt(Copy(ATexto, 1, 2)), AData);
end;

function TextoDataVazio(const ATexto: string): Boolean;
var
  vCaractere: Char;
begin
  Result := True;
  for vCaractere in ATexto do
    if EhDigito(vCaractere) then
      Exit(False);
end;

function DigitosIniciais(const ATexto: string): string;
var
  vPosicao: Integer;
  vEncontrouBuraco: Boolean;
begin
  Result := '';
  vEncontrouBuraco := False;

  for vPosicao := 1 to Length(ATexto) do
  begin
    if (vPosicao = POSICAO_BARRA_DIA) or (vPosicao = POSICAO_BARRA_MES) then
      Continue;

    if not EhDigito(ATexto[vPosicao]) then
      vEncontrouBuraco := True
    else if vEncontrouBuraco then
      Exit('')
    else
      Result := Result + ATexto[vPosicao];
  end;
end;

function SugerirData(const ADigitos: string; const AHoje: TDateTime): string;
var
  vDigitosHoje, vCompleta: string;
  vQuantidade, vInicioGrupo, vTamanhoEscrito: Integer;
  vData: TDateTime;
begin
  Result := '';

  vQuantidade := Length(ADigitos);
  if (vQuantidade = 0) or (vQuantidade >= QUANTIDADE_DIGITOS_DATA) then
    Exit;

  // Grupo em andamento: dia (1-2), mes (3-4) ou ano (5-8).
  if vQuantidade < 2 then
    vInicioGrupo := 1
  else if vQuantidade < 4 then
    vInicioGrupo := 3
  else
    vInicioGrupo := 5;

  vDigitosHoje := StringReplace(FormatarData(AHoje), '/', '', [rfReplaceAll]);
  vTamanhoEscrito := vQuantidade - vInicioGrupo + 1;
  if Copy(ADigitos, vInicioGrupo, vTamanhoEscrito) <> Copy(vDigitosHoje, vInicioGrupo, vTamanhoEscrito) then
    Exit;

  vCompleta := ADigitos + Copy(vDigitosHoje, vQuantidade + 1, QUANTIDADE_DIGITOS_DATA);
  vCompleta := Copy(vCompleta, 1, 2) + '/' + Copy(vCompleta, 3, 2) + '/' + Copy(vCompleta, 5, 4);

  if TryTextoParaData(vCompleta, vData) then
    Result := vCompleta;
end;

function DataInicialCalendario(const AData, AHoje: TDateTime): TDateTime;
begin
  if AData > 0 then
    Result := AData
  else
    Result := AHoje;
end;

function PrimeiraDataDaGrade(const AData: TDateTime): TDateTime;
var
  vAno, vMes, vDia: Word;
  vPrimeiroDia: TDateTime;
begin
  DecodeDate(AData, vAno, vMes, vDia);
  vPrimeiroDia := EncodeDate(vAno, vMes, 1);
  Result := vPrimeiroDia - (DayOfWeek(vPrimeiroDia) - 1);
end;

function NomeMesAno(const AData: TDateTime): string;
const
  NOMES_MES: array[1..12] of string = ('Janeiro', 'Fevereiro', 'Mar'#231'o', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro');
var
  vAno, vMes, vDia: Word;
begin
  DecodeDate(AData, vAno, vMes, vDia);
  Result := NOMES_MES[vMes] + ' ' + IntToStr(vAno);
end;

function NomeMesCurto(const AMes: Integer): string;
const
  NOMES_CURTOS: array[1..12] of string = ('Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez');
begin
  Result := NOMES_CURTOS[AMes];
end;

function PrimeiroAnoDaPagina(const AAno: Integer): Integer;
begin
  Result := AAno - AAno mod ANOS_POR_PAGINA;
end;

function PosicaoAposDigitos(const AQuantidade: Integer): Integer;
begin
  if AQuantidade < 2 then
    Result := AQuantidade
  else if AQuantidade < 4 then
    Result := AQuantidade + 1
  else
    Result := AQuantidade + 2;
end;

end.
