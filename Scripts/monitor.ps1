$linhas = Get-Content "C:\Projetos\MonitoraRibeirao\Job\servidores.txt"

while ($true) {

    Clear-Host

    $online = 0
    $offline = 0

    $tabela = ""

    $nomesPretos = @(
        "Circuito da sala (Alexa) (SEM ICMP)",
        "Circuito Externo (Alexa ECODOT 2) (SEM ICMP)"
    )

    foreach ($linha in $linhas) {

        if ($linha.Trim() -eq "") {
            continue
        }

        $dados = $linha.Split(";")

        $nome = $dados[0]
        $ip   = $dados[1]

        $teste = Test-Connection $ip -Count 1 -ErrorAction SilentlyContinue

        $ping = $null -ne $teste

        if ($ping) {

            $status = "<span style='color:#3fb950;font-weight:bold;text-shadow:0px 0px 8px #3fb950;'>UP</span>"
            $latencia = "$($teste.ResponseTime) ms"
            $cor = "#3a0f12"

            $online++

        }
        else {

            $status = "<span style='color:#f85149;font-weight:bold;text-shadow:0px 0px 8px #f85149;'>DOWN</span>"
            $latencia = "Timeout"
            $cor = "#f8d7da"

            $offline++
        }

        if (
            $nome -like "*Televisao*" -or
            $nome -like "*Notebook*" -or
            $nomesPretos -contains $nome
        ) {
            $nomeHtml = "<span style='color:black;font-weight:bold;'>$nome</span>"
        }
        else {
            $nomeHtml = $nome
        }

        $tabela += "
<tr style='background-color:$cor;'>
<td>$nomeHtml</td>
<td style='color:#ffffff;font-weight:bold;'>$ip</td>
<td>$status</td>
<td>$latencia</td>
<td style='color:#ffffff;font-weight:bold;'>$(Get-Date)</td>
</tr>
"
    }

$dataAtualizacao = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    $html = @"

<html>
<head>
<meta charset='UTF-8'>
<meta http-equiv='refresh' content='10'>

<style>

body {
    background-color: #0d1117;
    color: #c9d1d9;
    font-family: Consolas;
    margin: 30px;
}

h1 {
    color: #58a6ff;
    text-shadow: 0px 0px 10px #58a6ff;
    font-size: 38px;
}

h3 {
    font-size: 22px;
}

table {
    border-collapse: collapse;
    width: 95%;
    background-color: #161b22;
    box-shadow: 0px 0px 20px rgba(0,255,255,0.2);
}

th {
    background-color: #21262d;
    color: #58a6ff;
    padding: 15px;
    border: 1px solid #30363d;
    font-size: 16px;
}

td {
    padding: 14px;
    border: 1px solid #30363d;
    font-size: 15px;
    color: #e6edf3;
}

tr:hover {
    background-color: #1f2937;
    transition: 0.3s;
}

</style>

</head>

<body>

<h1>MONITOR DE REDE</h1>
<div style='
background-color:#161b22;
padding:15px;
margin-bottom:20px;
border-radius:10px;
box-shadow:0px 0px 10px rgba(88,166,255,0.2);
width:fit-content;
'>

<div style='color:#58a6ff;font-size:18px;font-weight:bold;'>
 Ultima atualização: $dataAtualizacao
</div>

<div style='color:#8b949e;font-size:15px;margin-top:5px;'>
 Proxima atualização em: 10 segundos
</div>

</div>

<h3 style='color:green;'>ONLINE: $online</h3>
<h3 style='color:red;'>OFFLINE: $offline</h3>

<table>

<tr>
<th>Nome</th>
<th>IP</th>
<th>Status</th>
<th>Ping</th>
<th>Data</th>
</tr>

$tabela

</table>

</body>
</html>

"@

    $relatorio = "C:\Projetos\MonitoraRibeirao\Relatorio\relatorio.html"

    $html | Set-Content $relatorio -Encoding UTF8

    Write-Host ""
    Write-Host "MONITOR EXECUTADO EM: $(Get-Date)"
    Write-Host $relatorio
    Write-Host ""

    Start-Sleep -Seconds 10
}