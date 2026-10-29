$script:vGerador = Join-Path $PSScriptRoot 'Gerar-Icones.ps1'
$script:vImagem = 'C:\CometERP\src\Mobile\assets\images\icon.png'

# Largura (em pixels) da faixa de colunas que têm algum pixel claro: mede quanto o símbolo ocupa.
function Get-LarguraClara {
    param([byte[]] $Bytes, [int] $Inicio, [int] $Lado)
    $vLinha = $Lado * 3 + ((4 - (($Lado * 3) % 4)) % 4)
    $vColunas = @()
    for ($vColuna = 0; $vColuna -lt $Lado; $vColuna++) {
        for ($vY = 0; $vY -lt $Lado; $vY++) {
            $vIndice = $Inicio + $vY * $vLinha + $vColuna * 3
            if ($Bytes[$vIndice] -gt 160 -and $Bytes[$vIndice + 1] -gt 160 -and $Bytes[$vIndice + 2] -gt 160) { $vColunas += $vColuna; break }
        }
    }
    if ($vColunas.Count -eq 0) { return 0 }
    ($vColunas | Measure-Object -Maximum).Maximum - ($vColunas | Measure-Object -Minimum).Minimum + 1
}

function Read-ResEntries {
    param([string] $Caminho)

    $vBytes = [IO.File]::ReadAllBytes($Caminho)
    $vEntradas = New-Object System.Collections.Generic.List[object]
    $vPosicao = 0
    while ($vPosicao -lt $vBytes.Length) {
        $vTamanhoDados = [BitConverter]::ToUInt32($vBytes, $vPosicao)
        $vTamanhoCabecalho = [BitConverter]::ToUInt32($vBytes, $vPosicao + 4)
        $vTipo = [BitConverter]::ToUInt16($vBytes, $vPosicao + 10)
        $vNome = ''
        $vCursor = $vPosicao + 12
        if ([BitConverter]::ToUInt16($vBytes, $vCursor) -ne 0xFFFF) {
            while (($vCaractere = [BitConverter]::ToUInt16($vBytes, $vCursor)) -ne 0) { $vNome += [char] $vCaractere; $vCursor += 2 }
        }
        $vInicioDados = $vPosicao + $vTamanhoCabecalho
        if ($vTamanhoDados -gt 0) {
            $vEntradas.Add([pscustomobject]@{
                Tipo    = $vTipo
                Nome    = $vNome
                Largura = [BitConverter]::ToInt32($vBytes, $vInicioDados + 4)
                Altura  = [BitConverter]::ToInt32($vBytes, $vInicioDados + 8)
                Bits    = [BitConverter]::ToUInt16($vBytes, $vInicioDados + 14)
                Pixel0  = ($vBytes[($vInicioDados + 40)..($vInicioDados + 42)] -join ',')
                Pixel1  = ($vBytes[($vInicioDados + 43)..($vInicioDados + 45)] -join ',')
                Largura_Clara = (Get-LarguraClara -Bytes $vBytes -Inicio ($vInicioDados + 40) -Lado ([BitConverter]::ToInt32($vBytes, $vInicioDados + 4)))
            })
        }
        $vPosicao = $vInicioDados + $vTamanhoDados
        $vPosicao += (4 - ($vPosicao % 4)) % 4
    }
    $vEntradas.ToArray()
}

Describe 'Gerar-Icones.ps1' {
    $vSaida = Join-Path $env:TEMP ('cmt-icones-' + [guid]::NewGuid().ToString('N') + '.res')
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:vGerador -Imagem $script:vImagem -Saida $vSaida | Out-Null
    $vCodigo = $LASTEXITCODE
    $vEntradas = if (Test-Path $vSaida) { Read-ResEntries $vSaida } else { @() }

    It 'termina com sucesso' {
        $vCodigo | Should Be 0
    }

    It 'gera um bitmap 24x24 por componente e o da tela de abertura' {
        $vNomes24 = @($vEntradas | Where-Object { $_.Largura -eq 24 } | ForEach-Object { $_.Nome } | Sort-Object)
        ($vNomes24 -join ',') | Should Be 'CMTSPLASH,TCMTBUTTON,TCMTCUSTOMBUTTON,TCMTDATEEDIT,TCMTDBGRID,TCMTINFOPANEL,TCMTMASKEDIT,TCMTNUMERICEDIT,TCMTPAGECONTROL,TCMTRADIOBUTTON'
    }

    It 'gera variantes 16 e 32 para a paleta' {
        ($vEntradas | Where-Object { $_.Nome -eq 'TCMTDBGRID16' }).Largura | Should Be 16
        ($vEntradas | Where-Object { $_.Nome -eq 'TCMTDBGRID32' }).Largura | Should Be 32
        @($vEntradas).Count | Should Be 28
    }

    It 'grava bitmaps de 24 bits do tipo BITMAP' {
        @($vEntradas | Where-Object { $_.Tipo -ne 2 -or $_.Bits -ne 24 }).Count | Should Be 0
        @($vEntradas | Where-Object { $_.Altura -ne $_.Largura }).Count | Should Be 0
    }

    It 'recorta a margem para o símbolo ocupar quase todo o ícone' {
        ($vEntradas | Where-Object { $_.Nome -eq 'CMTSPLASH' }).Largura_Clara -ge 20 | Should Be $true
    }

    It 'marca só o pixel inferior esquerdo como transparente (magenta)' {
        foreach ($vEntrada in $vEntradas) {
            $vEntrada.Pixel0 | Should Be '255,0,255'
            $vEntrada.Pixel1 | Should Not Be '255,0,255'
        }
    }

    if (Test-Path $vSaida) { Remove-Item $vSaida }

    It 'grava em Design\CMTIcones.res quando -Saida é omitido' {
        $vPadrao = Join-Path $PSScriptRoot 'CMTIcones.res'
        if (Test-Path $vPadrao) { Remove-Item $vPadrao }
        Push-Location $env:TEMP
        try { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:vGerador -Imagem $script:vImagem | Out-Null }
        finally { Pop-Location }
        $LASTEXITCODE | Should Be 0
        Test-Path $vPadrao | Should Be $true
    }
}
