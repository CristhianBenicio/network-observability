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
        $tipo = if ($dados.Length -ge 3 -and $dados[2].Trim() -ne "") { $dados[2].Trim().ToUpper() } else { "ICMP" }

        switch ($tipo) {
            "TCP" {
                $teste = Test-NetConnection -ComputerName $ip -Port 80 -WarningAction SilentlyContinue
                $ping = $null -ne $teste -and $teste.TcpTestSucceeded
                $tipoLabel = "TCP"
                if ($ping) {
                    $latencia = "Port 80"
                }
                else {
                    $latencia = "Timeout"
                }
            }
            default {
                $teste = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
                $ping = $null -ne $teste
                $tipoLabel = "ICMP"
                if ($ping) {
                    $latenciaClass = if ($teste.ResponseTime -gt 100) { "latency high" } else { "latency" }
                    $latencia = "<span class='$latenciaClass'>$($teste.ResponseTime) ms</span>"
                }
                else {
                    $latencia = "Timeout"
                }
            }
        }

        if ($ping) {
            $status = "<div class='status-badge status-up'><span class='status-dot'></span>ONLINE ($tipoLabel)</div>"
            $online++
        }
        else {
            $status = "<div class='status-badge status-down'><span class='status-dot'></span>OFFLINE ($tipoLabel)</div>"
            $offline++
        }

        $nomeHtml = $nome

        $tabela += "
<tr>
<td>$nomeHtml</td>
<td class='ip-address'>$ip</td>
<td>$status</td>
<td>$latencia</td>
<td>$(Get-Date -Format 'HH:mm:ss')</td>
</tr>
"
    }

$dataAtualizacao = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$totalServidores = $online + $offline
$percentualOnline = if ($totalServidores -gt 0) { [math]::Round(($online / $totalServidores) * 100, 1) } else { 0 }

    $html = @"
<!DOCTYPE html>
<html lang='pt-BR'>
<head>
    <meta charset='US-ASCII'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <meta http-equiv='refresh' content='10'>
    <title>Monitor de Rede - Ribeirao</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --bg-primary: #0f1419;
            --bg-secondary: #1a1f2e;
            --bg-tertiary: #242d3d;
            --accent: #00d4ff;
            --accent-hover: #00e5ff;
            --text-primary: #e4e9f0;
            --text-secondary: #a8b2c1;
            --success: #4ade80;
            --warning: #fbbf24;
            --danger: #f87171;
            --border: #2d3748;
        }

        body {
            background: linear-gradient(135deg, var(--bg-primary) 0%, #1a2332 100%);
            color: var(--text-primary);
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        /* Header */
        .header {
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }

        .header-title {
            flex: 1;
            min-width: 300px;
        }

        .header h1 {
            font-size: 2.2em;
            background: linear-gradient(135deg, var(--accent) 0%, #00a8cc 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 5px;
        }

        .header-date {
            display: flex;
            gap: 15px;
            align-items: center;
        }

        .update-info {
            background: linear-gradient(135deg, rgba(0, 212, 255, 0.1) 0%, rgba(0, 168, 204, 0.05) 100%);
            border: 1px solid rgba(0, 212, 255, 0.3);
            border-radius: 10px;
            padding: 12px 16px;
            font-size: 0.9em;
            min-width: 250px;
        }

        .update-info-label {
            color: var(--text-secondary);
            font-size: 0.8em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .update-info-value {
            color: var(--accent);
            font-weight: 700;
            margin-top: 3px;
        }

        /* KPI Grid */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .kpi-card {
            background: linear-gradient(135deg, var(--bg-secondary) 0%, var(--bg-tertiary) 100%);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 20px;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .kpi-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, var(--accent), transparent);
        }

        .kpi-card:hover {
            transform: translateY(-5px);
            border-color: var(--accent);
            box-shadow: 0 10px 30px rgba(0, 212, 255, 0.15);
        }

        .kpi-card.online::before {
            background: linear-gradient(90deg, var(--success), transparent);
        }

        .kpi-card.offline::before {
            background: linear-gradient(90deg, var(--danger), transparent);
        }

        .kpi-icon {
            font-size: 2.5em;
            margin-bottom: 10px;
        }

        .kpi-label {
            font-size: 0.85em;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }

        .kpi-value {
            font-size: 2.2em;
            font-weight: 800;
            line-height: 1;
            margin-bottom: 8px;
        }

        .kpi-card.online .kpi-value {
            color: var(--success);
        }

        .kpi-card.offline .kpi-value {
            color: var(--danger);
        }

        .kpi-percent {
            font-size: 0.9em;
            color: var(--text-secondary);
        }

        .kpi-percent strong {
            color: var(--accent);
            font-weight: 700;
        }

        /* Table Section */
        .table-section {
            background: linear-gradient(135deg, var(--bg-secondary) 0%, var(--bg-tertiary) 100%);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 25px;
            overflow-x: auto;
        }

        .table-title {
            font-size: 1.2em;
            font-weight: 700;
            margin-bottom: 20px;
            color: var(--text-primary);
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            background: linear-gradient(135deg, rgba(0, 212, 255, 0.1) 0%, rgba(0, 168, 204, 0.05) 100%);
            color: var(--accent);
            padding: 15px;
            text-align: left;
            font-weight: 700;
            border-bottom: 2px solid var(--border);
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        td {
            padding: 14px 15px;
            border-bottom: 1px solid rgba(45, 55, 72, 0.5);
            color: var(--text-primary);
            font-size: 0.95em;
        }

        tbody tr {
            transition: all 0.3s ease;
        }

        tbody tr:hover {
            background: linear-gradient(90deg, rgba(0, 212, 255, 0.05), transparent);
            border-left: 3px solid var(--accent);
            padding-left: 0;
        }

        td:first-child {
            font-weight: 600;
            color: var(--accent);
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 6px 12px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 0.85em;
        }

        .status-up {
            background: rgba(74, 222, 128, 0.15);
            color: var(--success);
        }

        .status-down {
            background: rgba(248, 113, 113, 0.15);
            color: var(--danger);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            display: inline-block;
            animation: pulse 2s infinite;
        }

        .status-up .status-dot {
            background: var(--success);
        }

        .status-down .status-dot {
            background: var(--danger);
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .ip-address {
            font-family: 'Courier New', monospace;
            color: var(--text-secondary);
            font-size: 0.9em;
        }

        .latency {
            font-family: 'Courier New', monospace;
        }

        .latency.high {
            color: var(--warning);
        }

        .latency.timeout {
            color: var(--danger);
        }

        /* Footer */
        .footer {
            margin-top: 30px;
            padding: 15px;
            text-align: center;
            color: var(--text-secondary);
            font-size: 0.85em;
            border-top: 1px solid var(--border);
        }

        /* Responsive */
        @media (max-width: 768px) {
            .header {
                flex-direction: column;
                align-items: flex-start;
            }

            .header-date {
                flex-direction: column;
                width: 100%;
            }

            .update-info {
                width: 100%;
            }

            .kpi-grid {
                grid-template-columns: repeat(2, 1fr);
            }

            .table-section {
                padding: 15px;
            }

            th, td {
                padding: 10px;
                font-size: 0.85em;
            }

            .header h1 {
                font-size: 1.8em;
            }
        }

        @media (max-width: 480px) {
            body {
                padding: 10px;
            }

            .kpi-grid {
                grid-template-columns: 1fr;
            }

            .kpi-value {
                font-size: 1.8em;
            }

            th, td {
                padding: 8px;
                font-size: 0.8em;
            }

            .status-badge {
                padding: 4px 8px;
                font-size: 0.75em;
            }
        }
    </style>
</head>

<body>
    <div class='container'>
        <!-- Header -->
        <div class='header'>
            <div class='header-title'>
                <h1>[NET] Monitor de Rede</h1>
            </div>
            <div class='header-date'>
                <div class='update-info'>
                    <div class='update-info-label'>Ultima Atualizacao</div>
                    <div class='update-info-value'>$dataAtualizacao</div>
                </div>
                <div class='update-info'>
                    <div class='update-info-label'>Proxima Atualizacao</div>
                    <div class='update-info-value'>10 segundos</div>
                </div>
            </div>
        </div>

        <!-- KPI Cards -->
        <div class='kpi-grid'>
            <div class='kpi-card online'>
                <div class='kpi-icon'>[OK]</div>
                <div class='kpi-label'>Servidor Online</div>
                <div class='kpi-value'>$online</div>
                <div class='kpi-percent'>de <strong>$totalServidores</strong> total</div>
            </div>

            <div class='kpi-card offline'>
                <div class='kpi-icon'>[!]</div>
                <div class='kpi-label'>Servidor Offline</div>
                <div class='kpi-value'>$offline</div>
                <div class='kpi-percent'>Atencao necessaria</div>
            </div>

            <div class='kpi-card'>
                <div class='kpi-icon'>[%]</div>
                <div class='kpi-label'>Taxa de Disponibilidade</div>
                <div class='kpi-value'>$percentualOnline%</div>
                <div class='kpi-percent'>Saude da rede</div>
            </div>
        </div>

        <!-- Table Section -->
        <div class='table-section'>
            <div class='table-title'>[SRV] Servidores Monitorados</div>
            <table>
                <thead>
                    <tr>
                        <th>Nome do Servidor</th>
                        <th>Endereco IP</th>
                        <th>Status</th>
                        <th>Latencia</th>
                        <th>Ultima Verificacao</th>
                    </tr>
                </thead>
                <tbody>
                    $tabela
                </tbody>
            </table>
        </div>

        <!-- Footer -->
        <div class='footer'>
            <p>Monitor de Rede Ribeirao - Atualiza a cada 10 segundos - Desenvolvido com PowerShell</p>
        </div>
    </div>
</body>

</html>

"@

    $relatorio = "C:\Projetos\MonitoraRibeirao\Relatorio\relatorio.html"

    $html | Set-Content $relatorio -Encoding ASCII

    Write-Host ""
    Write-Host "MONITOR EXECUTADO EM: $(Get-Date)"
    Write-Host $relatorio
    Write-Host ""

    Start-Sleep -Seconds 10
}