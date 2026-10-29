<#
.SYNOPSIS
    Gera Design\CMTIcones.res com os ícones do pacote CMT a partir de uma imagem.

.DESCRIPTION
    Bitmaps de 24 bits: CMTSPLASH (24x24, tela de abertura e Help > About) e, para cada
    componente, TCMT<CLASSE> (24x24) e as variantes 16 e 32 para a paleta. O pixel inferior
    esquerdo vira magenta porque a IDE usa a cor dele como transparente: assim só esse
    pixel some e o fundo da imagem é mantido.
    O .res é escrito direto (sem brcc32), no formato de recursos de 32 bits do Windows.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Design\Gerar-Icones.ps1 -Imagem C:\CometERP\src\Mobile\assets\images\icon.png
#>
param(
    [Parameter(Mandatory)] [string] $Imagem,
    [string] $Saida = ''
)

$ErrorActionPreference = 'Stop'
# No PowerShell 5.1 $PSScriptRoot fica vazio no valor padrão de parâmetro.
if (-not $Saida) { $Saida = Join-Path $PSScriptRoot 'CMTIcones.res' }
Add-Type -AssemblyName System.Drawing

$vClasses = @('TCMTBUTTON', 'TCMTCUSTOMBUTTON', 'TCMTDATEEDIT', 'TCMTDBGRID', 'TCMTINFOPANEL',
    'TCMTMASKEDIT', 'TCMTNUMERICEDIT', 'TCMTPAGECONTROL', 'TCMTRADIOBUTTON')

# Quadrado em volta do desenho (pixels diferentes da cor do canto), com 6% de margem: sem
# isso a margem da imagem original deixa o símbolo pequeno demais em 24x24.
function Get-AreaDoDesenho {
    param([System.Drawing.Bitmap] $Original)

    $vFundo = $Original.GetPixel(0, 0)
    $vPasso = [Math]::Max(1, [int] ($Original.Width / 256))
    $vMinimoX = $Original.Width; $vMinimoY = $Original.Height; $vMaximoX = 0; $vMaximoY = 0
    for ($vY = 0; $vY -lt $Original.Height; $vY += $vPasso) {
        for ($vX = 0; $vX -lt $Original.Width; $vX += $vPasso) {
            $vCor = $Original.GetPixel($vX, $vY)
            if ([Math]::Abs($vCor.R - $vFundo.R) + [Math]::Abs($vCor.G - $vFundo.G) + [Math]::Abs($vCor.B - $vFundo.B) -gt 60) {
                if ($vX -lt $vMinimoX) { $vMinimoX = $vX }
                if ($vX -gt $vMaximoX) { $vMaximoX = $vX }
                if ($vY -lt $vMinimoY) { $vMinimoY = $vY }
                if ($vY -gt $vMaximoY) { $vMaximoY = $vY }
            }
        }
    }
    if ($vMaximoX -le $vMinimoX) { return New-Object System.Drawing.Rectangle 0, 0, $Original.Width, $Original.Height }

    $vLado = [int] ([Math]::Max($vMaximoX - $vMinimoX, $vMaximoY - $vMinimoY) * 1.12)
    $vLado = [Math]::Min($vLado, [Math]::Min($Original.Width, $Original.Height))
    $vX = [Math]::Max(0, [Math]::Min($Original.Width - $vLado, [int] (($vMinimoX + $vMaximoX - $vLado) / 2)))
    $vY = [Math]::Max(0, [Math]::Min($Original.Height - $vLado, [int] (($vMinimoY + $vMaximoY - $vLado) / 2)))
    New-Object System.Drawing.Rectangle $vX, $vY, $vLado, $vLado
}

function ConvertTo-DibBytes {
    param([System.Drawing.Image] $Original, [System.Drawing.Rectangle] $Area, [int] $Tamanho)

    $vBitmap = New-Object System.Drawing.Bitmap $Tamanho, $Tamanho, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $vGraficos = [System.Drawing.Graphics]::FromImage($vBitmap)
    try {
        $vGraficos.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $vGraficos.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $vDestino = New-Object System.Drawing.Rectangle 0, 0, $Tamanho, $Tamanho
        $vGraficos.DrawImage($Original, $vDestino, $Area, [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally {
        $vGraficos.Dispose()
    }
    $vBitmap.SetPixel(0, $Tamanho - 1, [System.Drawing.Color]::FromArgb(255, 0, 255))

    $vFluxo = New-Object IO.MemoryStream
    try {
        $vBitmap.Save($vFluxo, [System.Drawing.Imaging.ImageFormat]::Bmp)
        $vBytes = $vFluxo.ToArray()
    }
    finally {
        $vFluxo.Dispose()
        $vBitmap.Dispose()
    }
    # Recurso BITMAP = arquivo .bmp sem o BITMAPFILEHEADER (14 bytes).
    $vBytes[14..($vBytes.Length - 1)]
}

function Add-Alinhamento {
    param([IO.BinaryWriter] $Escritor)
    while ($Escritor.BaseStream.Position % 4 -ne 0) { $Escritor.Write([byte] 0) }
}

function Write-ResEntry {
    param([IO.BinaryWriter] $Escritor, [string] $Nome, [byte[]] $Dados)

    $vNome = [Text.Encoding]::Unicode.GetBytes($Nome.ToUpperInvariant() + [char] 0)
    $vNomeAlinhado = $vNome.Length + ((4 - ($vNome.Length % 4)) % 4)
    $Escritor.Write([uint32] $Dados.Length)
    $Escritor.Write([uint32] (8 + 4 + $vNomeAlinhado + 16))
    $Escritor.Write([uint16] 0xFFFF)
    $Escritor.Write([uint16] 2)          # RT_BITMAP
    $Escritor.Write($vNome)
    Add-Alinhamento $Escritor
    $Escritor.Write([uint32] 0)          # DataVersion
    $Escritor.Write([uint16] 0x1030)     # MOVEABLE | PURE | DISCARDABLE
    $Escritor.Write([uint16] 0)          # idioma neutro
    $Escritor.Write([uint32] 0)          # Version
    $Escritor.Write([uint32] 0)          # Characteristics
    $Escritor.Write($Dados)
    Add-Alinhamento $Escritor
}

$vOriginal = New-Object System.Drawing.Bitmap (Resolve-Path $Imagem).Path
try {
    $vArea = Get-AreaDoDesenho -Original $vOriginal
    $vImagens = @{}
    foreach ($vTamanho in 16, 24, 32) { $vImagens[$vTamanho] = [byte[]] (ConvertTo-DibBytes -Original $vOriginal -Area $vArea -Tamanho $vTamanho) }
}
finally {
    $vOriginal.Dispose()
}

$vFluxo = [IO.File]::Create($Saida)
$vEscritor = New-Object IO.BinaryWriter $vFluxo
try {
    # Entrada vazia que abre todo .res de 32 bits.
    $vCabecalho = New-Object byte[] 32
    $vCabecalho[4] = 0x20
    $vCabecalho[8] = 0xFF; $vCabecalho[9] = 0xFF
    $vCabecalho[12] = 0xFF; $vCabecalho[13] = 0xFF
    $vEscritor.Write($vCabecalho)
    Write-ResEntry $vEscritor 'CMTSPLASH' $vImagens[24]
    foreach ($vClasse in $vClasses) {
        Write-ResEntry $vEscritor $vClasse $vImagens[24]
        Write-ResEntry $vEscritor "${vClasse}16" $vImagens[16]
        Write-ResEntry $vEscritor "${vClasse}32" $vImagens[32]
    }
}
finally {
    $vEscritor.Dispose()
}
Write-Host "Ícones gravados em $Saida"
