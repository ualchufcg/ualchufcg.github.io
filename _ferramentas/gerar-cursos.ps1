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

# fotos tiradas dos guias informativos, para quem nao tem foto no SIGAA
$fotosArq = Join-Path $raiz 'dados\fotos.psv'
$fotoPorNome = @{}
if (Test-Path $fotosArq) { foreach ($f in (Ler-Psv 'fotos.psv')) { $fotoPorNome[$f.nome] = $f.arquivo } }

# pos-doutorado nao e titulacao: exibe Doutorado
function Normaliza-Grau([string]$g) {
  if ($g -match 'P.s-?doutor') { 'Doutorado' } else { $g }
}

$buscaLattes = 'https://buscatextual.cnpq.br/buscatextual/busca.do?metodo=apresentar'

# logo e brasao reaproveitados da pagina principal
$indexAtual = Get-Content (Join-Path $raiz 'index.html') -Raw -Encoding UTF8
# o base64 pode estar em linha propria, logo o \s* depois do src="
$brasao = ([regex]'<img src="\s*(data:image/png;base64,[^"]+)"').Match($indexAtual).Groups[1].Value.Trim()
# logo da UAL, usada como selo na capa de cada curso
$marca  = ([regex]'class="selo"[^>]*src="\s*(data:image/png;base64,[^"]+)"').Match($indexAtual).Groups[1].Value.Trim()
if (-not $marca)  { throw "Nao encontrei a logo (class=selo) no index.html. As paginas sairiam com a imagem quebrada." }
if (-not $brasao) { throw "Nao encontrei o brasao no rodape do index.html." }

# versao do CSS no link: muda quando a folha muda, para o navegador
# do visitante nao ficar com o estilo antigo em cache
$cssVer = (Get-Item (Join-Path $raiz 'assets\estilo.css')).LastWriteTimeUtc.ToString('yyyyMMddHHmmss')

function Card-Docente($nomeBruto) {
  $siape  = $siapePorNome[$nomeBruto]
  $perfil = $perfilPorSiape[$siape]
  $nome   = Esc (Capitalizar $nomeBruto)
  $sb = New-Object System.Text.StringBuilder

  # foto do guia tem precedencia; depois a do SIGAA; por fim as iniciais
  $fotoLocal = $fotoPorNome[$nomeBruto]

  [void]$sb.Append("      <li class=""docente"">`n")
  if ($fotoLocal) {
    [void]$sb.Append("        <img class=""retrato"" src=""../../$(Esc $fotoLocal)"" alt="""" loading=""lazy"">`n")
  } elseif ($perfil -and $perfil.foto) {
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

  # ---- blocos iguais em todos os cursos: estagio, TCC e normas gerais ----
  [void]$h.Append(@"
  <section class="grupo">
    <h2>Estágio Supervisionado</h2>
    <p class="aviso">Cadastro do estágio obrigatório junto à Coordenação de Graduação em Letras</p>
    <nav class="links" aria-label="Estágio supervisionado">
      <a class="link" href="../../arquivos/estagios/manual-de-cadastro-de-estagio.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Manual de cadastro</span>
        <span class="nota">Passo a passo para registro do estágio</span>
      </a>
      <a class="link" href="../../arquivos/estagios/formulario-de-cadastro-de-estagio.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Formulário de sistematização das informações</span>
        <span class="nota">Concedente, escola, horário e plano de aulas &middot; para preenchimento e entrega</span>
      </a>
    </nav>
  </section>

  <section class="grupo">
    <h2>Defesa de Trabalho de Conclusão de Curso</h2>
    <p class="aviso">Matrícula em monografia, indicação de orientador e defesa &middot; tramitação pelo SEI</p>
    <div class="ficha">
      <p>Conforme o art. 143 da <a href="../../arquivos/normas/resolucao-cse-11-2024-regulamento-dos-cursos-de-graduacao.pdf" target="_blank" rel="noopener">Resolução CSE nº 11/2024</a>, compete à Coordenação do curso a mediação entre discentes e orientadores. A tramitação é feita por via digital, no SEI, para maior eficiência administrativa.</p>
    </div>
    <p class="aviso">O pedido deve observar a data limite determinada pela Administração Executiva Colegiada da UAL/CH ou pela coordenação do curso. Depois dessa data não são realizadas matrículas em monografia, nos termos do art. 254 da Resolução CSE nº 11/2024.</p>

    <h3>Fluxo de cadastramento e matrícula</h3>
    <ol class="passos">
      <li>
        <b>Abertura do processo</b>
        O discente abre no SEI um processo do tipo <i>Graduação: Trabalho de Conclusão de Curso (Matrícula/Indicação de Orientador)</i> e anexa o Formulário de Cadastro de Orientação Acadêmica preenchido e assinado.
      </li>
      <li>
        <b>Efetivação da matrícula</b>
        O TCC é atividade que não forma turma: pelo art. 256 da Resolução CSE nº 11/2024, a matrícula é realizada pela Coordenação do Curso, mediante pedido do próprio discente pelo sistema de gestão acadêmica.
      </li>
      <li>
        <b>Mudança de fase processual</b>
        Depois da matrícula, a Coordenação altera o tipo do processo para <i>Graduação: Defesa de Trabalho de Conclusão de Curso</i>.
      </li>
      <li>
        <b>Documentação pós-defesa</b>
        Versão final do TCC acompanhada da folha de aprovação assinada pela banca e da ficha catalográfica.
      </li>
    </ol>

    <h3>Ficha catalográfica</h3>
    <p class="aviso">Solicitada à Biblioteca Central depois da defesa, antes do depósito do trabalho</p>
    <ol class="passos">
      <li>
        <b>Solicitação</b>
        Preencha o modelo de formulário e reúna o trabalho acadêmico completo, com a folha de aprovação datada e assinada pela banca examinadora &mdash; as assinaturas podem ser de próprio punho ou eletrônicas. Envie os dois arquivos para <a href="mailto:fichacatalografica@setor.ufcg.edu.br">fichacatalografica@setor.ufcg.edu.br</a>.
      </li>
      <li>
        <b>Formatação</b>
        Apresente o trabalho conforme a ABNT NBR 14724:2024. O documento de orientações traz o check-list dos elementos essenciais exigidos para o depósito na Biblioteca Digital de Teses e Dissertações (BDTD) da UFCG.
      </li>
      <li>
        <b>Depósito na BDTD</b>
        Abra no SEI um processo específico para o depósito, escolhendo entre <i>depósito autorizado</i>, em que o trabalho fica disponível à comunidade, e <i>depósito embargado</i>, com acesso restrito por três anos &mdash; usado quando há pedido de patente ou informações confidenciais.
      </li>
      <li>
        <b>Depósito no SIGAA</b>
        Procure a coordenação do curso para orientação quanto ao depósito do TCC no SIGAA.
      </li>
    </ol>
    <div class="ficha">
      <p>Biblioteca Central da UFCG</p>
      <ul>
        <li><a href="mailto:fichacatalografica@setor.ufcg.edu.br">fichacatalografica@setor.ufcg.edu.br</a> &middot; <a href="tel:+558321011098">(83) 2101-1098</a> (Setor de Referência)</li>
        <li><a href="mailto:bibliotecacentral@setor.ufcg.edu.br">bibliotecacentral@setor.ufcg.edu.br</a> &middot; <a href="tel:+558321011090">(83) 2101-1090</a> &middot; <a href="tel:+558321011101">(83) 2101-1101</a></li>
      </ul>
    </div>

    <h3>Documentos</h3>
    <nav class="links" aria-label="Documentos da defesa de TCC">
      <a class="link" href="../../arquivos/tcc/formulario-de-cadastro-de-orientacao-academica.docx" download>
        <span class="rotulo">Formulário de cadastro de orientação acadêmica<span class="formato">DOCX</span></span>
        <span class="nota">Anexo obrigatório na abertura do processo no SEI &middot; preencher e assinar</span>
      </a>
      <a class="link" href="../../arquivos/tcc/orientacoes-ficha-catalografica.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Orientações para a ficha catalográfica</span>
        <span class="nota">Passos da solicitação, check-list da ABNT NBR 14724 e tutorial de depósito</span>
      </a>
      <a class="link" href="../../arquivos/tcc/modelo-de-formulario-para-solicitacao-de-ficha-catalografica.docx" download>
        <span class="rotulo">Modelo de formulário para solicitação de ficha catalográfica<span class="formato">DOCX</span></span>
        <span class="nota">Enviar preenchido à Biblioteca Central junto com o trabalho</span>
      </a>
    </nav>
  </section>

  <section class="grupo">
    <h2>Normas e diretrizes</h2>
    <p class="aviso">Normas da UFCG que alcançam todos os cursos de graduação da UAL/CH</p>
    <nav class="links" aria-label="Normas e diretrizes">
      <a class="link" href="../../arquivos/normas/resolucao-cse-11-2024-regulamento-dos-cursos-de-graduacao.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Resolução CSE nº 11/2024 &mdash; Regulamento dos Cursos de Graduação</span>
        <span class="nota">Norma principal da graduação na UFCG &middot; edição revisada &middot; matrícula, avaliação, estágio, TCC e colação de grau</span>
      </a>
      <a class="link" href="../../arquivos/normas/resolucao-sods-09-2026-regulamento-de-ensino-titulo-vii.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Resolução SODS nº 09/2026</span>
        <span class="nota">Atualiza o Título VII &mdash; Do Ingresso &mdash; da Resolução CSE nº 11/2024</span>
      </a>
      <a class="link" href="../../arquivos/normas/instrucao-normativa-pre-01-2025-faltas-e-exercicios-domiciliares.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Instrução Normativa PRE nº 1/2025</span>
        <span class="nota">Justificativa de faltas e regime de exercícios domiciliares &middot; documentos exigidos em cada situação</span>
      </a>
      <a class="link" href="../../arquivos/normas/portaria-pre-28-2025-antecipacao-de-estudos.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Portaria PRE nº 28/2025</span>
        <span class="nota">Antecipação de estudos para abreviar a duração do período letivo</span>
      </a>
      <a class="link" href="../../arquivos/normas/resolucao-02-2023-politica-de-assistencia-estudantil.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Resolução nº 02/2023</span>
        <span class="nota">Política de Assistência Estudantil da UFCG</span>
      </a>
      <a class="link" href="../../arquivos/normas/regimento-geral-ufcg.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Regimento Geral da UFCG</span>
        <span class="nota">Estrutura, órgãos e competências da Universidade</span>
      </a>
    </nav>
  </section>

"@)

  [void]$h.Append("  <section class=""grupo"">`n    <h2>Corpo docente</h2>`n")
  [void]$h.Append("    <p class=""aviso"">Dados do SIGAA, atualizados pelos próprios docentes</p>`n")

  if ($docEf.Count) {
    [void]$h.Append("    <h3 class=""subtitulo"">Efetivos</h3>`n    <ul class=""docentes"">`n")
    foreach ($d in $docEf) { [void]$h.Append((Card-Docente $d.nome)) }
    [void]$h.Append("    </ul>`n")
  }
  if ($docSub.Count) {
    [void]$h.Append("    <h3 class=""subtitulo"">Substitutos</h3>`n    <ul class=""docentes"">`n")
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
