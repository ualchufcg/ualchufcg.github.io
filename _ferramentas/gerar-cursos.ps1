# ---------------------------------------------------------------
#  Gera uma pagina por curso a partir dos arquivos em \dados
#  Uso:  powershell -ExecutionPolicy Bypass -File _ferramentas\gerar-cursos.ps1
# ---------------------------------------------------------------
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Ler-Psv([string]$arquivo) {
  Import-Csv -Path (Join-Path $raiz "dados\$arquivo") -Delimiter '|' -Encoding UTF8
}
function Esc([string]$t) {
  if ($null -eq $t) { return "" }
  $t.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}
function Capitalizar([string]$nome) {
  $miudas = @('de','da','do','das','dos','e')
  ($nome.ToLower() -split ' ' | ForEach-Object {
     if ($miudas -contains $_) { $_ }
     else { if ($_.Length -gt 0) { $_.Substring(0,1).ToUpper() + $_.Substring(1) } }
   }) -join ' '
}
function Iniciais([string]$nome) {
  $p = ($nome -split ' ') | Where-Object { $_.Length -gt 2 }
  if ($p.Count -ge 2) { ($p[0][0] + $p[-1][0]).ToUpper() }
  elseif ($p.Count -eq 1) { $p[0].Substring(0,1).ToUpper() }
  else { "?" }
}

$cursos   = Ler-Psv 'cursos.psv'
$nomes    = Ler-Psv 'docentes.psv'
$vinculos = Ler-Psv 'docentes-por-curso.psv'
$perfis   = Ler-Psv 'perfis-sigaa.psv'
$emails   = Ler-Psv 'emails.psv'
# perfis revisados pela coordenacao: tem precedencia sobre o SIGAA
$lattesArq = Join-Path $raiz 'dados\perfis-lattes.psv'
$lattes = if (Test-Path $lattesArq) { Ler-Psv 'perfis-lattes.psv' } else { @() }

$siapePorNome   = @{}; foreach ($n in $nomes)  { $siapePorNome[$n.nome] = $n.siape }
$perfilPorSiape = @{}; foreach ($p in $perfis) { $perfilPorSiape[$p.siape] = $p }
$emailPorNome   = @{}; foreach ($e in $emails) { $emailPorNome[$e.nome] = $e.email }
$lattesPorNome  = @{}; foreach ($l in $lattes) { $lattesPorNome[$l.nome] = $l }

# pos-doutorado nao e titulacao: exibe Doutorado
function Normaliza-Grau([string]$g) {
  if ($g -match 'P.s-?doutor') { 'Doutorado' } else { $g }
}

$buscaLattes = 'https://buscatextual.cnpq.br/buscatextual/busca.do?metodo=apresentar'

# logo e brasao reaproveitados da pagina principal
$indexAtual = Get-Content (Join-Path $raiz 'index.html') -Raw -Encoding UTF8
$brasao = ([regex]'<img src="(data:image/png;base64,[^"]+)"').Match($indexAtual).Groups[1].Value
# logo da UAL, usada como selo na capa de cada curso
$marca  = ([regex]'class="marca" src="(data:image/png;base64,[^"]+)"').Match($indexAtual).Groups[1].Value

# versao do CSS no link: muda quando a folha muda, para o navegador
# do visitante nao ficar com o estilo antigo em cache
$cssVer = (Get-Item (Join-Path $raiz 'assets\estilo.css')).LastWriteTimeUtc.ToString('yyyyMMddHHmmss')

function Card-Docente($nomeBruto) {
  $siape  = $siapePorNome[$nomeBruto]
  $perfil = $perfilPorSiape[$siape]
  $nome   = Esc (Capitalizar $nomeBruto)
  $sb = New-Object System.Text.StringBuilder

  [void]$sb.Append("      <li class=""docente"">`n")
  if ($perfil -and $perfil.foto) {
    [void]$sb.Append("        <img class=""retrato"" src=""$(Esc $perfil.foto)"" alt="""" loading=""lazy"" referrerpolicy=""no-referrer"">`n")
  } else {
    [void]$sb.Append("        <div class=""semfoto"" aria-hidden=""true"">$(Iniciais $nomeBruto)</div>`n")
  }
  # a coordenacao tem precedencia; o SIGAA e a reserva
  $rev    = $lattesPorNome[$nomeBruto]
  $grau   = Normaliza-Grau $(if ($rev -and $rev.grau)   { $rev.grau }   elseif ($perfil) { $perfil.grau }   else { '' })
  $texto  =                $(if ($rev -and $rev.resumo) { $rev.resumo } elseif ($perfil) { $perfil.areas } else { '' })
  $urlLat =                $(if ($rev -and $rev.lattes) { $rev.lattes } elseif ($perfil) { $perfil.lattes } else { '' })

  [void]$sb.Append("        <div class=""corpo"">`n")
  [void]$sb.Append("          <p class=""nome"">$nome</p>`n")
  if ($grau) {
    [void]$sb.Append("          <span class=""grau"">$(Esc $grau)</span>`n")
  }
  if ($texto) {
    [void]$sb.Append("          <p class=""areas"">$(Esc $texto)</p>`n")
  }
  [void]$sb.Append("          <ul class=""vias"">`n")
  [void]$sb.Append("            <li><a href=""https://sigaa.ufcg.edu.br/sigaa/public/docente/portal.jsf?siape=$siape"" target=""_blank"" rel=""noopener"">Perfil no SIGAA</a></li>`n")
  if ($urlLat) {
    # nem todo link e do Lattes: rotula conforme o destino
    $rotulo = if ($urlLat -match 'lattes|cnpq') { 'Lattes' } else { 'Perfil' }
    [void]$sb.Append("            <li><a href=""$(Esc $urlLat)"" target=""_blank"" rel=""noopener"">$rotulo</a></li>`n")
  } else {
    [void]$sb.Append("            <li><a href=""$buscaLattes"" target=""_blank"" rel=""noopener"" title=""Este docente não informou o Lattes no SIGAA"">Buscar no Lattes</a></li>`n")
  }
  $mail = $emailPorNome[$nomeBruto]
  if ($mail) {
    [void]$sb.Append("            <li><a href=""mailto:$(Esc $mail)"">E-mail</a></li>`n")
  }
  [void]$sb.Append("          </ul>`n        </div>`n      </li>`n")
  $sb.ToString()
}

$resumo = @()

foreach ($c in $cursos) {
  $docEf  = @($vinculos | Where-Object { $_.curso -eq $c.slug -and $_.vinculo -eq 'efetivo' }    | Sort-Object nome)
  $docSub = @($vinculos | Where-Object { $_.curso -eq $c.slug -and $_.vinculo -eq 'substituto' } | Sort-Object nome)

  $h = New-Object System.Text.StringBuilder
  [void]$h.Append(@"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(Esc $c.nome) ($(Esc $c.turno.ToLower())) · UAL/CH · UFCG</title>
<meta name="description" content="$(Esc $c.nome) — $(Esc $c.turno.ToLower()). Estrutura curricular, Projeto Pedagógico, coordenação e corpo docente. Unidade Acadêmica de Letras, UFCG.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../../assets/estilo.css?v=$cssVer">
<style>
  :root{--cor:$($c.cor);--cor-escura:$($c.corEscura);--cor-clara:$($c.corClara)}
</style>
</head>
<body>

<main class="pagina">

  <div class="capa">
    <a class="voltar" href="../../">&larr; Unidade Acadêmica de Letras</a>
    <img class="selo" src="$marca" alt="">
    <p class="licenciatura">Licenciatura</p>
    <h1>Letras</h1>
    <svg class="rasgo" viewBox="0 0 300 12" preserveAspectRatio="none" aria-hidden="true">
      <path d="M0 12 L0 6.2 L9 4.1 L17 7.3 L26 3.4 L34 6.8 L43 2.9 L52 6.1 L60 3.2 L69 7.4 L78 4.3 L86 7.9 L95 3.6 L104 6.7 L112 2.8 L121 6.4 L130 3.9 L138 7.6 L147 4.2 L156 7.1 L164 3.3 L173 6.6 L182 2.7 L190 6.9 L199 4.4 L208 7.8 L216 3.5 L225 6.3 L234 2.6 L242 7.2 L251 4.6 L260 7.7 L268 3.8 L277 6.5 L286 2.9 L294 6.8 L300 4.7 L300 12 Z" fill="var(--papel)"/>
    </svg>
    <div class="faixa-curso">
      <span class="idioma">$(Esc ($c.nome -replace '^Letras\s*(—|-)\s*','' -replace '^Letras\s+',''))</span>
      <span class="turno">$(Esc $c.turno)</span>
    </div>
    <svg class="rasgo rasgo-fim" viewBox="0 0 300 12" preserveAspectRatio="none" aria-hidden="true">
      <path d="M0 0 L0 5.8 L9 7.9 L17 4.7 L26 8.6 L34 5.2 L43 9.1 L52 5.9 L60 8.8 L69 4.6 L78 7.7 L86 4.1 L95 8.4 L104 5.3 L112 9.2 L121 5.6 L130 8.1 L138 4.4 L147 7.8 L156 4.9 L164 8.7 L173 5.4 L182 9.3 L190 5.1 L199 7.6 L208 4.2 L216 8.5 L225 5.7 L234 9.4 L242 4.8 L251 7.4 L260 4.3 L268 8.2 L277 5.5 L286 9.1 L294 5.2 L300 7.3 L300 0 Z" fill="var(--papel)"/>
    </svg>
    <p class="unidade">Centro de Humanidades &middot; UFCG</p>
  </div>

  <section class="grupo">
    <h2>Coordenação</h2>
    <div class="ficha">
      <p>Coordenação: $(Esc $c.coordenacao)<br>Secretaria da CGLET: Marciano Siqueira e Hermes Levi</p>
      <ul>
        <li><a href="mailto:gradletrasual@gmail.com">gradletrasual@gmail.com</a></li>
        <li><a href="mailto:marciano.siqueira@tecnico.ufcg.edu.br">marciano.siqueira@tecnico.ufcg.edu.br</a></li>
        <li><a href="mailto:hermes.levi@ufcg.edu.br">hermes.levi@ufcg.edu.br</a></li>
        <li><a href="https://wa.me/558321011036" target="_blank" rel="noopener">(83) 2101-1036 &mdash; WhatsApp</a></li>
      </ul>
    </div>
  </section>

  <section class="grupo">
    <h2>Documentos do curso</h2>
    <nav class="links" aria-label="Documentos do curso">

"@)
  [void]$h.Append("      <a class=""link"" href=""../../$($c.fluxograma)"" target=""_blank"" rel=""noopener"">`n")
  [void]$h.Append("        <span class=""rotulo"">Estrutura curricular e fluxograma</span>`n")
  [void]$h.Append("        <span class=""nota"">Componentes por período e pré-requisitos</span>`n      </a>`n")
  if ($c.ppc) {
    [void]$h.Append("      <a class=""link"" href=""../../$($c.ppc)"" target=""_blank"" rel=""noopener"">`n")
    [void]$h.Append("        <span class=""rotulo"">Projeto Pedagógico do Curso</span>`n")
    [void]$h.Append("        <span class=""nota"">Concepção, objetivos, perfil do egresso e avaliação</span>`n      </a>`n")
  } else {
    [void]$h.Append("      <span class=""link pendente"">`n        <span class=""rotulo"">Projeto Pedagógico do Curso</span>`n        <span class=""nota"">Aguardando envio pela coordenação</span>`n      </span>`n")
  }
  [void]$h.Append("    </nav>`n  </section>`n`n")

  $total = $docEf.Count + $docSub.Count
  [void]$h.Append("  <section class=""grupo"">`n    <h2>Corpo docente</h2>`n")
  [void]$h.Append("    <p class=""aviso"">$total docentes &middot; dados do SIGAA, atualizados pelos próprios docentes</p>`n")

  if ($docEf.Count) {
    [void]$h.Append("    <h3 class=""subtitulo"">Efetivos<span>$($docEf.Count)</span></h3>`n    <ul class=""docentes"">`n")
    foreach ($d in $docEf) { [void]$h.Append((Card-Docente $d.nome)) }
    [void]$h.Append("    </ul>`n")
  }
  if ($docSub.Count) {
    [void]$h.Append("    <h3 class=""subtitulo"">Substitutos<span>$($docSub.Count)</span></h3>`n    <ul class=""docentes"">`n")
    foreach ($d in $docSub) { [void]$h.Append((Card-Docente $d.nome)) }
    [void]$h.Append("    </ul>`n")
  }
  [void]$h.Append("  </section>`n`n")

  [void]$h.Append(@"
  <footer>
    <img src="$brasao" alt="">
    <div class="creditos">
      <p>UNIVERSIDADE FEDERAL DE CAMPINA GRANDE<br>Centro de Humanidades<br>Unidade Acadêmica de Letras</p>
      <p>Elaborado por Hermes Levi — Servidor TAE</p>
      <p>Atualizado em novembro de 2026.</p>
      <p><a href="../../">Voltar à página da UAL</a></p>
    </div>
  </footer>

</main>
</body>
</html>
"@)

  $pasta = Join-Path $raiz "cursos\$($c.slug)"
  New-Item -ItemType Directory -Force -Path $pasta | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $pasta 'index.html'), $h.ToString(), $utf8)

  $resumo += [pscustomobject]@{
    Curso = $c.slug; Efetivos = $docEf.Count; Substitutos = $docSub.Count
    Fotos = @($docEf + $docSub | Where-Object { $p = $perfilPorSiape[$siapePorNome[$_.nome]]; $p -and $p.foto }).Count
    PPC = if ($c.ppc) { "sim" } else { "FALTA" }
  }
}

$resumo | Format-Table -AutoSize
Write-Output "paginas geradas em $raiz\cursos"
