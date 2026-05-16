<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
/* ===================== PRODUTOS ===================== */
Connection conP = null;
PreparedStatement psP = null;
ResultSet rsP = null;

try {
  conP = dbConnect();
  psP = conP.prepareStatement(
    "SELECT id, nome, descricao, categoria, preco " +
    "FROM produtos WHERE ativo=1 ORDER BY categoria, nome"
  );
  rsP = dbQuery(conP, psP);
} catch(Exception e) {
  out.print("Erro ao carregar produtos: " + e.getMessage());
}

/* ===================== PROMOÇÕES (LISTA) ===================== */
Connection conPr = null;
PreparedStatement psPr = null;
ResultSet rsPr = null;

try {
  conPr = dbConnect();
  psPr = conPr.prepareStatement(
    "SELECT id, titulo, descricao, desconto_percent, data_inicio, data_fim, criado_em " +
    "FROM promocoes " +
    "WHERE ativa=1 " +
    "ORDER BY criado_em DESC " +
    "LIMIT 10"
  );
  rsPr = dbQuery(conPr, psPr);
} catch(Exception e) {
  out.print("Erro ao carregar promoções: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="style.css">
  <title>FelixUberShop</title>
</head>
<body>

<header>
  <nav class="navbar">
    <a class="brand" href="index.jsp">
      <img src="legumes.png" class="logo" alt="FelixUberShop">
    </a>

    <ul class="menu">
      <li><a class="active" href="index.jsp">Home</a></li>
      <li><a href="#produtos">Produtos</a></li>
      <li><a href="#promocoes">Promoções</a></li>
      <li><a href="#horarios">Horários &amp; Localização</a></li>
      <li><a href="#" id="abrirLoginLink">Login</a></li>
      <li><a href="#" id="abrirRegistarLink">Inscrever-se</a></li>
    </ul>
  </nav>
</header>

<main>
  <section class="destaque">
    <div class="destaque-texto">
      <h1>O melhor da Páscoa, esteja onde estiver</h1><br><h2>Visita a FelixUberShop</h2><br><br>
      <p>
        Na véspera da páscoa, encomende entradas, pratos de carne, peixe ou vegetarianos,
        sobremesas e muito mais para partilhar com a sua família e amigos.
      </p>
      

      
    </div>

    <div class="destaque-imagem">
      <img src="pascua.png" alt="Destaque Páscoa">
    </div>
  </section><br><br>

  <!-- ===================== PRODUTOS ===================== -->
  <section id="produtos" class="produtos">
    <div class="produtos-topo">
      <h2>Produtos mercearia</h2>
    </div><br><br>

    <div class="produtos-grid">
      <%
        boolean temProdutos = false;
        while (rsP != null && rsP.next()) {
          temProdutos = true;

          String pNome = rsP.getString("nome");
          String pDesc = rsP.getString("descricao");
          String pCat  = rsP.getString("categoria");
          double pPreco = rsP.getDouble("preco");
      %>

        <article class="produto-card">
          <div class="produto-info">
            <p class="produto-nome"><%= pNome %></p><br>

            <p class="produto-desc">
              <%= (pDesc != null && !pDesc.trim().isEmpty()) ? pDesc : (pCat != null ? pCat : "") %>
            </p><br>

            <div class="produto-precos">
              <span class="preco-atual"><%= String.format("%.2f €", pPreco) %></span>
            </div>

          </div>
        </article>

      <%
        }
        if (!temProdutos) {
      %>
        <p style="grid-column:1/-1;">Sem produtos disponíveis no momento.</p>
      <%
        }
      %>
    </div>
  </section><br><br>

  <!-- ===================== PROMOÇÕES  ===================== -->
  <section id="promocoes" class="promo">
    <div class="promo-container">

      <div class="promo-topo">
        <div>
          <p class="promo-kicker">Poupe na sua mercearia, todos os dias.</p>
          <h2 class="promo-titulo">Promoções encontras aqui</h2>
        </div>

        <a class="promo-botao" href="#produtos">Ver produtos</a>
      </div>

      <!-- grelha com promoções -->
      <div class="promo-cards">
        <%
          boolean temPromo = false;

          while (rsPr != null && rsPr.next()) {
            temPromo = true;

            String titulo = rsPr.getString("titulo");
            String desc   = rsPr.getString("descricao");
            Integer pct   = (Integer) rsPr.getObject("desconto_percent");
            Date di       = rsPr.getDate("data_inicio");
            Date df       = rsPr.getDate("data_fim");
        %>

          <article class="promo-card no-img">
            <h3><%= titulo %></h3>

            <p class="promo-desc"><%= (desc != null ? desc : "") %></p>

            <p class="promo-info">
              <strong>Desconto:</strong> <%= (pct == null ? "—" : (pct + "%")) %>
            </p>

            <p class="promo-info">
              <strong>Período:</strong>
              <%= (di != null ? di.toString() : "—") %> → <%= (df != null ? df.toString() : "—") %>
            </p>
          </article>

        <%
          }

          if (!temPromo) {
        %>
          <article class="promo-card no-img">
            <h3>Sem promoções no momento</h3>
            <p class="promo-desc">Volte mais tarde para ver novidades.</p>
          </article>
        <%
          }
        %>
      </div>

    </div>
  </section><br><br>

  <section id="horarios" class="horarios"></section>
</main><br><br>

<footer class="footer">
  <div class="footer-container">
    <div class="footer-col brand-col">
      <p class="footer-small">
        <a href="#horarios" class="footer-link">Localização</a><br><br>
        PRACETA DOUTOR MANUEL PIRES BENTO <br> LOTE 13 <br>Nº 4, CV A <br>
        6000-123 Castelo Branco
      </p>
    </div>

    <div class="footer-col">
      <h4>Contactos</h4>
      <ul>
        <li><a href="#">+351 965 801 515</a></li>
        <li><a href="#">+351 931 400 174</a></li>
      </ul>
    </div>

    <div class="footer-col">
      <h4>Horario de funcionamento</h4>
       <p class="footer-contact">
        Estamos aberto <br> das 8h às 19h
       </p>
    </div>

    <div class="footer-col">
    </div>
  </div>
</footer>

<!-- =================== MODAL LOGIN =================== -->
<div id="loginModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>Login</h2>
      <a href="#" class="modal-close" id="fecharLoginLink">✕</a>
    </div>

    <form action="login_conect.jsp" method="POST" class="login-form">
      Utilizador
      <input type="text" id="utilizador" name="utilizador" required>
      Senha
      <input type="password" id="senha" name="senha" required>
      <button type="submit" class="btn-submit">Entrar</button>
    </form>

    <p class="modal-note">
      Ainda não tens conta? <a href="#" id="abrirRegistarDentroLogin">Inscrever-se</a>
    </p>
  </div>
</div>

<!-- =================== MODAL REGISTO =================== -->
<div id="registarModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>Criar conta</h2>
      <a href="#" class="modal-close" id="fecharRegistarLink">✕</a>
    </div>

    <p class="modal-note">
      A conta ficará <strong>pendente</strong> até aprovação do administrador.
    </p>

    <form action="index_registar.jsp" method="POST" class="login-form">
      <label>Username</label>
      <input type="text" name="username" required>

      <label>Password</label>
      <input type="password" name="password" required>

      <label>Nome</label>
      <input type="text" name="nome">

      <label>Email</label>
      <input type="email" name="email">

      <label>Telefone</label>
      <input type="text" name="telefone">

      <label>Morada</label>
      <input type="text" name="morada">

      <button type="submit" class="btn-submit">Criar conta</button>
    </form>
  </div>
</div>

<script>
  // ===== Helpers =====
  const params = new URLSearchParams(window.location.search);
  const reg = params.get("reg"); // ok | ja_existe | campos

  // ===== Login Modal =====
  const loginModal = document.getElementById("loginModal");
  const abrirLogin = document.getElementById("abrirLoginLink");
  const abrirLoginFooter = document.getElementById("abrirLoginLinkFooter");
  const fecharLogin = document.getElementById("fecharLoginLink");

  function openLogin(e){
    if(e) e.preventDefault();
    loginModal.classList.add("show");
  }

  if (abrirLogin) abrirLogin.addEventListener("click", openLogin);
  if (abrirLoginFooter) abrirLoginFooter.addEventListener("click", openLogin);

  if (fecharLogin) fecharLogin.addEventListener("click", function(e){
    e.preventDefault();
    loginModal.classList.remove("show");
  });

  loginModal.addEventListener("click", function(e){
    if(e.target.id === "loginModal") loginModal.classList.remove("show");
  });

  // ===== Registar Modal =====
  const registarModal = document.getElementById("registarModal");
  const abrirRegistar = document.getElementById("abrirRegistarLink");
  const abrirRegistarFooter = document.getElementById("abrirRegistarLinkFooter");
  const abrirRegistarDentroLogin = document.getElementById("abrirRegistarDentroLogin");
  const fecharRegistar = document.getElementById("fecharRegistarLink");

  function openRegistar(e){
    if(e) e.preventDefault();
    registarModal.classList.add("show");
    loginModal.classList.remove("show");
  }

  if (abrirRegistar) abrirRegistar.addEventListener("click", openRegistar);
  if (abrirRegistarFooter) abrirRegistarFooter.addEventListener("click", openRegistar);
  if (abrirRegistarDentroLogin) abrirRegistarDentroLogin.addEventListener("click", openRegistar);

  if (fecharRegistar) fecharRegistar.addEventListener("click", function(e){
    e.preventDefault();
    registarModal.classList.remove("show");
  });

  registarModal.addEventListener("click", function(e){
    if(e.target.id === "registarModal") registarModal.classList.remove("show");
  });

  // ===== Auto abrir registo + mensagens =====
  if (reg) {
    openRegistar();
    if (reg === "ok") alert("Conta criada com sucesso! Aguarde aprovação do administrador.");
    if (reg === "ja_existe") alert("Esse username já existe. Escolha outro.");
    if (reg === "campos") alert("Preencha username e password.");
  }

  // ===== ESC fecha tudo =====
  document.addEventListener("keydown", function(e){
    if(e.key === "Escape") {
      loginModal.classList.remove("show");
      registarModal.classList.remove("show");
    }
  });
</script>

</body>
</html>