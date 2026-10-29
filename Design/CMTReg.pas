unit CMTReg;

// Identificação do pacote na IDE: tela de abertura e Help > About.
// Os ícones da paleta (TCMT<CLASSE>) vêm do mesmo CMTIcones.res, por nome de classe.

interface

procedure Register;

implementation

{$R CMTIcones.res}

uses
  Winapi.Windows, System.SysUtils, ToolsAPI;

const
  cTitulo = 'CMT Componentes';
  cDescricao = 'Componentes visuais do CometERP: botões, grade, campos de data, número e ' +
    'máscara, painel de informação, page control e radio button.';
  cImagem = 'CMTSPLASH';

var
  vIndiceSobre: Integer = -1;

procedure Register;
var
  vSobre: IOTAAboutBoxServices;
begin
  if (vIndiceSobre = -1) and Supports(BorlandIDEServices, IOTAAboutBoxServices, vSobre) then
    vIndiceSobre := vSobre.AddPluginInfo(cTitulo, cDescricao, LoadBitmap(HInstance, cImagem));
end;

procedure RemoverSobre;
var
  vSobre: IOTAAboutBoxServices;
begin
  if (vIndiceSobre <> -1) and Supports(BorlandIDEServices, IOTAAboutBoxServices, vSobre) then
    vSobre.RemovePluginInfo(vIndiceSobre);
  vIndiceSobre := -1;
end;

initialization
  // Só existe durante a abertura da IDE; instalando o pacote depois, não há tela de abertura.
  if Assigned(SplashScreenServices) then
    SplashScreenServices.AddPluginBitmap(cTitulo, LoadBitmap(HInstance, cImagem));

finalization
  RemoverSobre;

end.
