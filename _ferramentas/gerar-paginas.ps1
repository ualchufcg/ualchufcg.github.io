# -----------------------------------------------------------------
#  Gera as paginas internas que nao sao de curso: CALET, Central de
#  Linguas (proficiencia e cursos de extensao) e Monitoria.
#  A capa e o rodape saem daqui para nao divergirem entre si nem
#  das paginas de curso.
# -----------------------------------------------------------------
$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

foreach ($img in @('assets\logo-ual.png','assets\brasao-ufcg.png')) {
  if (-not (Test-Path (Join-Path $raiz $img))) { throw "Falta $img. As paginas sairiam com a imagem quebrada." }
}
$cssVer = (Get-Item (Join-Path $raiz 'assets\estilo.css')).LastWriteTimeUtc.ToString('yyyyMMddHHmmss')

$rasgoCima  = '<path d="M0 12 L0 6.2 L9 4.1 L17 7.3 L26 3.4 L34 6.8 L43 2.9 L52 6.1 L60 3.2 L69 7.4 L78 4.3 L86 7.9 L95 3.6 L104 6.7 L112 2.8 L121 6.4 L130 3.9 L138 7.6 L147 4.2 L156 7.1 L164 3.3 L173 6.6 L182 2.7 L190 6.9 L199 4.4 L208 7.8 L216 3.5 L225 6.3 L234 2.6 L242 7.2 L251 4.6 L260 7.7 L268 3.8 L277 6.5 L286 2.9 L294 6.8 L300 4.7 L300 12 Z" fill="var(--papel)"/>'
$rasgoBaixo = '<path d="M0 0 L0 5.8 L9 7.9 L17 4.7 L26 8.6 L34 5.2 L43 9.1 L52 5.9 L60 8.8 L69 4.6 L78 7.7 L86 4.1 L95 8.4 L104 5.3 L112 9.2 L121 5.6 L130 8.1 L138 4.4 L147 7.8 L156 4.9 L164 8.7 L173 5.4 L182 9.3 L190 5.1 L199 7.6 L208 4.2 L216 8.5 L225 5.7 L234 9.4 L242 4.8 L251 7.4 L260 4.3 L268 8.2 L277 5.5 L286 9.1 L294 5.2 L300 7.3 L300 0 Z" fill="var(--papel)"/>'

function Pagina {
  param(
    [string]$destino,    # pasta relativa a raiz
    [int]$nivel,         # quantos ../ ate a raiz
    [string]$titulo,     # <title>
    [string]$descricao,
    [string]$chapeu,     # linha pequena acima do nome
    [string]$h1,
    [string]$faixa,      # nome completo na faixa branca
    [string]$etiqueta,   # pilula abaixo da faixa (pode ficar vazia)
    [string]$cor, [string]$corEscura, [string]$corClara,
    [string]$corpo
  )
  $r = '../' * $nivel
  $pilula = ''
  if ($etiqueta) { $pilula = "`n      <span class=""turno"">$etiqueta</span>" }

  $h = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$titulo</title>
<meta name="description" content="$descricao">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="${r}assets/estilo.css?v=$cssVer">
<style>
  :root{--cor:$cor;--cor-escura:$corEscura;--cor-clara:$corClara}
</style>
</head>
<body>

<main class="pagina">

  <div class="capa">
    <a class="voltar" href="$r">&larr; Unidade Acadêmica de Letras</a>
    <img class="selo" src="${r}assets/logo-ual.png" alt="">
    <p class="licenciatura">$chapeu</p>
    <h1>$h1</h1>
    <svg class="rasgo" viewBox="0 0 300 12" preserveAspectRatio="none" aria-hidden="true">
      $rasgoCima
    </svg>
    <div class="faixa-curso">
      <span class="idioma">$faixa</span>$pilula
    </div>
    <svg class="rasgo rasgo-fim" viewBox="0 0 300 12" preserveAspectRatio="none" aria-hidden="true">
      $rasgoBaixo
    </svg>
    <p class="unidade">Centro de Humanidades &middot; UFCG</p>
  </div>

$corpo
  <footer>
    <img src="${r}assets/brasao-ufcg.png" alt="">
    <div class="creditos">
      <p>UNIVERSIDADE FEDERAL DE CAMPINA GRANDE<br>Centro de Humanidades<br>Unidade Acadêmica de Letras</p>
      <p>Elaborado por Hermes Levi — Servidor TAE</p>
      <p>Atualizado em novembro de 2026.</p>
      <p><a href="$r">Voltar à página da UAL</a></p>
    </div>
  </footer>

</main>
</body>
</html>
"@
  $pasta = Join-Path $raiz $destino
  New-Item -ItemType Directory -Force -Path $pasta | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $pasta 'index.html'), $h, $utf8)
  Write-Output "  $destino/index.html"
}

Write-Output "paginas internas:"

# ----------------------------------------------------------------- CALET
Pagina -destino 'calet' -nivel 1 `
  -titulo 'CALET — Centro Acadêmico de Letras Álvaro Luiz · UAL/CH · UFCG' `
  -descricao 'Centro Acadêmico de Letras Álvaro Luiz: atuação, gestão, contatos e a história do poeta que dá nome à entidade.' `
  -chapeu 'Centro Acadêmico' -h1 'CALET' `
  -faixa 'Centro Acadêmico de Letras Álvaro Luiz' -etiqueta 'Entidade estudantil' `
  -cor '#6F5A94' -corEscura '#443562' -corClara '#EFEBF7' `
  -corpo @"
  <section class="grupo">
    <p class="tarja">O CALET</p>
    <div class="texto">
      <p>É a entidade representativa máxima dos estudantes dos cursos de Letras — Língua Portuguesa, Inglesa, Espanhola, Francesa e Libras — da Unidade Acadêmica de Letras.</p>
      <p>Historicamente combativo e culturalmente ativo, o CALET constitui-se como o espaço físico e virtual de conforto, amparo e busca por direitos para todos os alunos e alunas. Mais do que uma representação burocrática, o Centro atua como um polo de fomento ao pensamento crítico e à integração universitária.</p>
    </div>

    <h3>Atuação</h3>
    <nav class="links" aria-label="Atuação do CALET">
      <span class="link encerrado">
        <span class="rotulo">Defesa estudantil</span>
        <span class="nota">Representação discente nos colegiados da UAL e do Centro de Humanidades</span>
      </span>
      <span class="link encerrado">
        <span class="rotulo">Cultura e ciência</span>
        <span class="nota">Organização da tradicional Semana de Letras da UFCG (SELET) e apoio a grupos de estudo</span>
      </span>
      <span class="link encerrado">
        <span class="rotulo">Acolhimento</span>
        <span class="nota">Recepção aos calouros e mediação de demandas junto à coordenação</span>
      </span>
    </nav>
  </section>

  <section class="grupo">
    <h2>Gestão</h2>
    <div class="ficha">
      <ul>
        <li><b>Presidência</b> — Rafael (Letras — Língua Inglesa)</li>
        <li><b>Vice-presidência</b> — Jay Dantas (Letras Libras)</li>
        <li><b>Tesouraria</b> — Emanuel (Língua Portuguesa, diurno) e Helly (Língua Portuguesa, noturno)</li>
        <li><b>Comunicação</b> — Graziele, Thiago André e Giovana (Língua Portuguesa, noturno)</li>
        <li><b>Assistência Estudantil</b> — Sarah Rizya (Língua Portuguesa, diurno)</li>
      </ul>
    </div>
    <nav class="links" aria-label="Contatos do CALET">
      <a class="link" href="https://www.instagram.com/caletrasufcg/" target="_blank" rel="noopener">
        <span class="rotulo">@caletrasufcg no Instagram</span>
        <span class="nota">Avisos, eventos e campanhas do Centro Acadêmico</span>
      </a>
      <a class="link" href="https://chat.whatsapp.com/EOxLVasKhMa4auE5uYyHyq" target="_blank" rel="noopener">
        <span class="rotulo">Grupo no WhatsApp</span>
        <span class="nota">Canal aberto aos estudantes dos cursos de Letras</span>
      </a>
    </nav>
  </section>

  <section class="grupo">
    <h2>Nossa história: quem foi Álvaro Luiz?</h2>
    <figure class="perfil">
      <img src="../assets/calet/alvaro-luiz.jpg" alt="Retrato de Álvaro Luís Guedes Pinheiro">
      <figcaption>Álvaro Luís Guedes Pinheiro (1960–1981)</figcaption>
    </figure>
    <div class="texto">
      <p>O Centro Acadêmico carrega com orgulho o nome do poeta <b>Álvaro Luís Guedes Pinheiro (1960–1981)</b>, uma homenagem que mantém viva a memória daquele que foi um dos mais promissores estudantes de Letras desta instituição.</p>
      <p>Álvaro Luiz foi aluno do curso quando a atual UFCG ainda era o Campus II da Universidade Federal da Paraíba. Poeta de sensibilidade aguçada e intelectual rigoroso, destacava-se entre seus pares pela dedicação à escrita e pela defesa da qualidade acadêmica. Relatos de colegas da época o descrevem como um estudante à frente de seu tempo, que insistia na prática exaustiva da reescrita textual como caminho para a excelência literária.</p>
      <p>Sua trajetória foi interrompida precocemente aos 21 anos, em março de 1981. Embora sua vida tenha sido breve, o impacto de sua presença no Campus Bodocongó foi tão marcante que, após seu falecimento, o movimento estudantil decidiu eternizar seu nome na entidade que representa os futuros profissionais das Letras.</p>
      <p>Álvaro Luiz simboliza o ideal do estudante de Letras da UFCG: apaixonado pela palavra, engajado com a cultura e eterno aprendiz da linguagem.</p>
    </div>
  </section>

"@

# ------------------------------------------------- Central de Linguas: proficiencia
Pagina -destino 'central-de-linguas\proficiencia' -nivel 2 `
  -titulo 'Proficiência em Leitura · Central de Línguas Estrangeiras · UAL/CH · UFCG' `
  -descricao 'Exame de Proficiência em Leitura de Línguas Estrangeiras da UFCG: editais, provas, gabaritos, resultado e certificados.' `
  -chapeu 'Central de Línguas Estrangeiras' -h1 'Proficiência' `
  -faixa 'Exame de Proficiência em Leitura de Línguas Estrangeiras' -etiqueta 'Pós-graduação' `
  -cor '#2A6B78' -corEscura '#1B4852' -corClara '#E4F2F5' `
  -corpo @"
  <section class="grupo">
    <p class="aviso">Destinado a discentes da pós-graduação da UFCG. Espanhol, francês, inglês e português como língua não materna.</p>
    <div class="ficha">
      <p>Secretaria: Veralucia</p>
      <ul>
        <li><a href="mailto:proficiencia@setor.ufcg.edu.br">proficiencia@setor.ufcg.edu.br</a></li>
        <li><a href="tel:+558321015816">(83) 2101-5816</a></li>
      </ul>
    </div>

    <h3>Editais</h3>
    <nav class="links" aria-label="Proficiência: editais">
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/editais/edital-01-2026-normas-do-exame.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 01/2026 — normas do exame</span>
        <span class="nota">Público-alvo, áreas, inscrição e pagamento · 4 de agosto</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/editais/edital-02-2026-isencao-deferimentos.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 02/2026 — isenção da taxa</span>
        <span class="nota">Pedidos deferidos · 13 de agosto</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/editais/edital-03-2026-retificacao-do-edital-02.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 03/2026 — retificação do Edital 02</span>
        <span class="nota">Lista de isenções retificada · 13 de agosto</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/editais/edital-04-2026-retificacao-do-edital-01.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 04/2026 — retificação do Edital 01</span>
        <span class="nota">Dados da GRU para pagamento · 17 de agosto</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/editais/edital-05-2026-inscricoes-deferidas.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 05/2026 — inscrições deferidas</span>
        <span class="nota">Locais, datas e horários das provas · 31 de agosto</span>
      </a>
    </nav>

    <h3>Provas e gabarito</h3>
    <nav class="links" aria-label="Proficiência: provas e gabarito">
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/provas/prova-espanhol-2026.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Prova de Língua Espanhola</span>
        <span class="nota">Aplicada em 15 de setembro</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/provas/prova-frances-2026.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Prova de Língua Francesa</span>
        <span class="nota">Aplicada em 16 de setembro</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/provas/prova-ingles-2026.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Prova de Língua Inglesa</span>
        <span class="nota">Aplicada em 17 de setembro</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/provas/prova-portugues-lingua-nao-materna-2026.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Prova de Português como Língua Não Materna</span>
        <span class="nota">Aplicada em 18 de setembro</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/gabarito/edital-06-2026-gabaritos-preliminares.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 06/2026 — gabaritos preliminares</span>
        <span class="nota">As quatro provas · 18 de setembro</span>
      </a>
    </nav>

    <h3>Resultado e certificados</h3>
    <nav class="links" aria-label="Proficiência: resultado e certificados">
      <a class="link" href="../../arquivos/central-de-linguas/proficiencia-2026/resultados/edital-07-2026-homologacao-do-resultado-final.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Edital 07/2026 — homologação do resultado final</span>
        <span class="nota">Resultado, recursos e regras de certificação · 30 de setembro</span>
      </a>
      <a class="link" href="https://sei.ufcg.edu.br/sei/modulos/pesquisa/md_pesq_processo_exibir.php?Q0wza50AQFvcHUN8prp4JA94f6WHgbxxyxbvP6EhggrRgrJgEVF70Iire3yMx1M9RjwpXh1Ov5x25Uv58cv-himlpdGIDvpvfNwVflQA7vhtPY0czuPdGqvK9r7G_u5e" target="_blank" rel="noopener">
        <span class="rotulo">Certificados de aprovação</span>
        <span class="nota">Consulta ao processo no SEI · emissão a partir de 16 de outubro</span>
      </a>
    </nav>
  </section>

"@

# ------------------------------------------------- Central de Linguas: extensao
Pagina -destino 'central-de-linguas\cursos-de-extensao' -nivel 2 `
  -titulo 'Cursos de Extensão · Central de Línguas Estrangeiras · UAL/CH · UFCG' `
  -descricao 'Cursos de línguas estrangeiras da Central de Línguas da UFCG, abertos à comunidade a partir de 16 anos.' `
  -chapeu 'Central de Línguas Estrangeiras' -h1 'Extensão' `
  -faixa 'Cursos de línguas abertos à comunidade' -etiqueta 'A partir de 16 anos' `
  -cor '#2A6B78' -corEscura '#1B4852' -corClara '#E4F2F5' `
  -corpo @"
  <section class="grupo">
    <p class="aviso">Cursos de línguas estrangeiras ofertados pela Central de Línguas, abertos à comunidade a partir de 16 anos.</p>
    <div class="ficha">
      <p>Secretaria: Veralucia</p>
      <ul>
        <li><a href="mailto:proficiencia@setor.ufcg.edu.br">proficiencia@setor.ufcg.edu.br</a></li>
        <li><a href="tel:+558321015816">(83) 2101-5816</a></li>
      </ul>
    </div>

    <h3>Francês I — 2026.2</h3>
    <nav class="links" aria-label="Curso de Extensão em Francês I">
      <a class="link" href="../../arquivos/central-de-linguas/cursos-de-extensao/frances-1/regras/regras-curso-frances-i.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Regras de participação</span>
        <span class="nota">48 horas · 30 vagas · Prof. Dr. Wescley Batista Lopes · aulas de 29/09 a 18/12</span>
      </a>
      <a class="link" href="../../arquivos/central-de-linguas/cursos-de-extensao/frances-1/resultados/resultado-das-inscricoes-frances-i.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Resultado das inscrições</span>
        <span class="nota">Os 30 selecionados, horários e sala · 28 de setembro</span>
      </a>
      <span class="link encerrado">
        <span class="rotulo">Inscrições</span>
        <span class="nota">Realizadas de 23 a 25 de setembro</span>
      </span>
      <span class="link pendente">
        <span class="rotulo">Declaração de conclusão</span>
        <span class="nota">Para participantes aprovados, ao fim do curso em 18 de dezembro</span>
      </span>
    </nav>
  </section>

"@

# ------------------------------------------------- Monitoria
Pagina -destino 'monitoria' -nivel 1 `
  -titulo 'Programas de Monitoria · UAL/CH · UFCG' `
  -descricao 'Coordenação dos Programas de Monitoria da Unidade Acadêmica de Letras: componentes com monitoria em 2026.2 e contato.' `
  -chapeu 'Coordenação dos Programas de' -h1 'Monitoria' `
  -faixa 'Programas de Monitoria da UAL/CH' -etiqueta '2026.2' `
  -cor '#243E8F' -corEscura '#16295C' -corClara '#E9EEF9' `
  -corpo @"
  <section class="grupo">
    <p class="aviso">Setor responsável pela seleção e pelo acompanhamento dos monitores da unidade</p>
    <div class="ficha">
      <p>Coordenação: Profa. Marcelle Ventura Carvalho</p>
      <ul>
        <li><a href="mailto:marcellevcarvalho@gmail.com">marcellevcarvalho@gmail.com</a></li>
      </ul>
    </div>

    <h3>Componentes 2026.2 — Edital PRE nº 42/2026</h3>
    <nav class="links" aria-label="Componentes da monitoria 2026.2">
      <a class="link" href="../arquivos/monitoria-2026-2/estudos-linguisticos-contemporaneos-t2.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Estudos Linguísticos Contemporâneos (T2)</span>
        <span class="nota">Código 1307204 — Agnaldo Almeida de Jesus</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/fonetica-e-fonologia-da-lingua-inglesa.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Fonética e Fonologia da Língua Inglesa</span>
        <span class="nota">Código 1307224 — Almir Anacleto de Araújo Gomes</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/ingles.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Inglês</span>
        <span class="nota">Código 1307150 — Almir Anacleto de Araújo Gomes</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/leitura-e-escrita-teorias-sociocognitivas.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Leitura e Escrita: Teorias Sociocognitivas</span>
        <span class="nota">Código 1307194 — Elizabeth Maria da Silva</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/lingua-francesa-ii.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Língua Francesa II</span>
        <span class="nota">Código 1307202 — Lino Dias Correia Neto</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/lingua-inglesa-ii.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Língua Inglesa II</span>
        <span class="nota">Código 1307203 — Cleydstone Chaves dos Santos</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/lingua-inglesa-iv-t01.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Língua Inglesa IV — T01</span>
        <span class="nota">Código 1307228 — Matheus Lucas de Almeida</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/lingua-portuguesa-turmas-02-04-e-05.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Língua Portuguesa — turmas 02, 04 e 05</span>
        <span class="nota">Código 1307169 — Jeferson Silva da Cruz</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/literatura-brasileira-contemporanea.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Literatura Brasileira Contemporânea</span>
        <span class="nota">Código 1307282 — Tássia Tavares de Oliveira</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/metodologia-e-tecnicas-de-pesquisa-turma-01.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Metodologia e Técnicas de Pesquisa — turma 01</span>
        <span class="nota">Código 1307177 — Jeferson Silva da Cruz</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/morfologia-de-classes.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Morfologia de Classes</span>
        <span class="nota">Código 1307232 — Anderson Monteiro Andrade</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/sintaxe-interoracional.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Sintaxe Interoracional</span>
        <span class="nota">Código 1307212 — Anderson Monteiro Andrade</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/tel-gramatica-tradicional.pdf" target="_blank" rel="noopener">
        <span class="rotulo">TEL — Gramática Tradicional</span>
        <span class="nota">Código 1307270 — Anderson Monteiro Andrade e Maria Angélica de Oliveira</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/teoria-da-narrativa.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Teoria da Narrativa</span>
        <span class="nota">Código 1307201 — Clara Matheus Nogueira</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/teoria-do-texto-poetico-t01.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Teoria do Texto Poético — T01</span>
        <span class="nota">Código 1307195 — Lorena Gois de Lima Cavalcante</span>
      </a>
      <a class="link" href="../arquivos/monitoria-2026-2/teorias-e-praticas-de-producao-oral-em-lingua-inglesa-t01.pdf" target="_blank" rel="noopener">
        <span class="rotulo">Teorias e Práticas de Produção Oral em Língua Inglesa — T01</span>
        <span class="nota">Código 1307236 — Matheus Lucas de Almeida</span>
      </a>
    </nav>
  </section>

"@

Write-Output "pronto"
