<%@ page contentType="text/html; charset=UTF-8" %>

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
      <h1>O melhor da Páscoa, esteja onde estiver</h1>
      <p>
        Na véspera da páscoa, encomende entradas, pratos de carne, peixe ou vegetarianos,
        sobremesas e muito mais para partilhar com a sua família e amigos.
      </p><br><br>

      <a class="btn-destaque" href="#produtos">Encomendar</a>
    </div>

    <div class="destaque-imagem">
      <img src="pascua.png" alt="Destaque Páscoa">
    </div>
  </section><br><br>

  <section id="produtos" class="produtos">
    <div class="produtos-topo">
      <h2>Produtos mercearia</h2>
    </div><br><br>

    <div class="produtos-grid">

      <article class="produto-card">
        <div class="produto-img">
          <img src="snack.jpg" alt="Snack e batatas">
        </div>
        <div class="produto-info">
          <p class="produto-nome">Snack e batatas</p>
          <p class="produto-desc">0,75 L</p>

          <div class="produto-precos">
            <span class="preco-atual">10,29 €</span>
            <span class="preco-antigo">12,69 €</span>
          </div>

          <button class="btn-adicionar" type="button">Adicionar</button>
        </div>
      </article>

      <article class="produto-card">
        <div class="produto-img">
          <img src="frutas.jpg" alt="Frutas e legumes">
        </div>
        <div class="produto-info">
          <p class="produto-nome">Frutas e legumes</p>
          <p class="produto-desc">KG</p>

          <div class="produto-precos">
            <span class="preco-atual">5,99 €</span>
            <span class="preco-antigo">7,49 €</span>
          </div>

          <button class="btn-adicionar" type="button">Adicionar</button>
        </div>
      </article>

      <article class="produto-card">
        <div class="produto-img">
          <img src="laticinios-1.jpg" alt="Laticínios e Queijos">
        </div>
        <div class="produto-info">
          <p class="produto-nome">Laticínios e Queijos</p>
          <p class="produto-desc">0,7 KG</p>

          <div class="produto-precos">
            <span class="preco-atual">7,99 €</span>
            <span class="preco-antigo">8,99 €</span>
          </div>

          <button class="btn-adicionar" type="button">Adicionar</button>
        </div>
      </article>

      <article class="produto-card">
        <div class="produto-img">
          <img src="padaria.jpg" alt="Padaria">
        </div>
        <div class="produto-info">
          <p class="produto-nome">Padaria</p>
          <p class="produto-desc">KG</p>

          <div class="produto-precos">
            <span class="preco-atual">2,29 €</span>
            <span class="preco-antigo">2,79 €</span>
          </div>

          <button class="btn-adicionar" type="button">Adicionar</button>
        </div>
      </article>

    </div>
  </section><br><br>

  <section id="promocoes" class="promo">
    <div class="promo-container">

      <div class="promo-topo">
        <p class="promo-kicker">Poupe na sua mercearia, todos os dias.</p>
        <h2 class="promo-titulo">Promoções da Semana</h2>
        <a class="promo-botao" href="#produtos">Ver produtos</a>
      </div>

      <div class="promo-grid">

        <div class="promo-numeros">
          <div class="numero-card">
            <span class="numero">+20</span>
            <span class="label">Produtos em promoção</span>
          </div>
          <div class="numero-card">
            <span class="numero">-15%</span>
            <span class="label">Desconto em frescos</span>
          </div>
        </div>

        <div class="promo-cards">
          <article class="promo-card">
            <img src="fruta_epoca.jpg" alt="Fruta da época">
            <h3>Fruta da Época</h3>
            <p class="promo-desc">Maçã, banana e laranja com desconto até domingo.</p>
            <p class="promo-info"><strong>Maior saída:</strong> Laranja 1kg — <span class="preco">1,49€</span></p>
          </article>

          <article class="promo-card">
            <img src="leite_iogurte.png" alt="Laticínios">
            <h3>Laticínios</h3>
            <p class="promo-desc">Leite e iogurtes para a sua semana com preço especial.</p>
            <p class="promo-info"><strong>Maior saída:</strong> Leite 1L — <span class="preco">0,99€</span></p>
          </article>
        </div>

      </div>

    </div>
  </section><br><br>

  <section id="horarios" class="horarios"></section>
</main><br><br>

<footer class="footer">
  <div class="footer-container">

    <div class="footer-col brand-col">
      <div class="footer-brand">
        <img src="legumes.png" alt="Legumes - FelixUberShop" class="footer-logo">
        <div>
          <h3>FelixUberShop</h3>
          <p>A sua mercearia em Faro, com encomendas rápidas e promoções semanais.</p>
        </div>
      </div><br>

      <p class="footer-small">
        <a href="#horarios" class="footer-link">Horários &amp; Localização</a><br>
        Travessa Fonseca Domingo<br>
        8000-536 Faro, Portugal
      </p>
    </div>

    <div class="footer-col">
      <h4>Mapa do site</h4>
      <ul>
        <li><a href="index.jsp">Home</a></li>
        <li><a href="#produtos">Produtos</a></li>
        <li><a href="#promocoes">Promoções</a></li>
        <li><a href="#horarios">Horários &amp; Localização</a></li>
        <li><a href="#" id="abrirLoginLinkFooter">Login</a></li>
        <li><a href="#" id="abrirRegistarLinkFooter">Inscrever-se</a></li>
      </ul>
    </div>

    <div class="footer-col">
      <h4>Políticas</h4>
      <ul>
        <li><a href="#">Termos e Condições</a></li>
        <li><a href="#">Política de Privacidade</a></li>
        <li><a href="#">Política de Cookies</a></li>
        <li><a href="#">Livro de Reclamações</a></li>
      </ul>
    </div>

    <div class="footer-col">
      <h4>Apoio ao Cliente</h4>
      <p class="footer-contact">
        <strong>Email:</strong> apoio@felixubershop.pt<br>
        <strong>Telefone:</strong> 800 000 000 (número gratuito)<br>
        <strong>Telefone:</strong> 289 000 000 (rede fixa nacional)<br><br>
        <strong>Horário:</strong><br>
        Dias úteis das 8h às 19h
      </p>
    </div>

  </div>

  <div class="footer-bottom">
    <p>© 2026 FelixUberShop — Todos os direitos reservados.</p>
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