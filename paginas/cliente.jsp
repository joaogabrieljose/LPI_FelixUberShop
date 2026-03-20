<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>


<%-- Restrição de acesso: apenas CLIENTE --%>
<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");

if (perfil == null || userId == null || !perfil.equalsIgnoreCase("CLIENTE")) {
    response.sendRedirect("index.jsp?acesso=negado");
    return;
}

String username = (String) session.getAttribute("username");
%>




<%-- Buscar dados pessoais na BD --%>
<%
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nome = "";
String email = "";
String telefone = "";
String morada = "";

try {
    con = dbConnect();
    ps = con.prepareStatement("SELECT nome, email, telefone, morada FROM utilizadores WHERE id=? LIMIT 1");
    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        nome = rs.getString("nome") != null ? rs.getString("nome") : "";
        email = rs.getString("email") != null ? rs.getString("email") : "";
        telefone = rs.getString("telefone") != null ? rs.getString("telefone") : "";
        morada = rs.getString("morada") != null ? rs.getString("morada") : "";
    }
} catch (Exception e) {
    out.print("Erro ao carregar dados: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}
%>


<%-- Buscar produtos na BD --%>

<%
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
} catch (Exception e) {
    out.print("Erro ao carregar produtos: " + e.getMessage());
}
%>



<%-- Consultar saldo da carteira do utilizador --%>
<%
Connection conS = null;
PreparedStatement psS = null;
ResultSet rsS = null;

int carteiraId = 0;
double saldoAtual = 0.0;

try {
    conS = dbConnect();
    psS = conS.prepareStatement(
        "SELECT id, saldo FROM carteiras WHERE utilizador_id=? AND tipo='UTILIZADOR' LIMIT 1"
    );
    psS.setInt(1, userId);
    rsS = dbQuery(conS, psS);

    if (rsS.next()) {
        carteiraId = rsS.getInt("id");
        saldoAtual = rsS.getDouble("saldo");
    }
} catch (Exception e) {
    out.print("Erro ao carregar saldo: " + e.getMessage());
} finally {
    dbClose(rsS, psS, conS);
}
%>


<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Dashboard Cliente - FelixUberShop</title>
  <link rel="stylesheet" href="cliente.css">
  <link rel="stylesheet" href="cliente_dados_pessoais.css">
  <link rel="stylesheet" href="cliente_produtos.css">


</head>
<body>

<header class="dash-top">
  <div class="dash-brand">
    <a class="brand" href="index.jsp">
	    <img src="legumes.png" class="logo" alt="FelixUberShop">
	</a>
    <div>
      <h1>FelixUberShop</h1>
      <p>Área do Cliente</p>
    </div>
  </div>

  <div class="dash-user">
    <span class="pill">👤 <%= username %></span>
  </div>
</header>

<div class="dash-layout">

  <!-- Menu lateral (usa o teu nav class="menu") -->
  <aside class="dash-side">
    <nav class="menu">
      <a class="active" href="cliente.jsp">Dashboard</a>
      <a href="#" id="abrirDadosLink">dados pessoais</a>
      <a href="#" id="abrirProdutosLink">Consultar produtos</a>
      <a href="#" id="abrirSaldoLink">Saldo</a>
      <a href="#">Encomendas</a>
      <a href="#">Carteira</a>
      <a href="logout.jsp">logout</a>
    </nav>
  </aside>

  <!-- Conteúdo principal -->
  <main class="dash-main">

    <!-- Hero / destaque (tipo estrutura de dashboard) -->
    <section class="dash-hero">
      <div class="dash-hero-text">
        <h2>Bem-vindo(a), <%= username %>!</h2>
        <p>Veja as suas encomendas, saldo e promoções da semana num só lugar.</p>
        <div class="dash-actions">
          <a class="btn" href="#">Ver Produtos</a>
          <a class="btn outline" href="#">Ver Promoções</a>
        </div>
      </div>
    </section>

    <!-- Cards rápidos (resumo) -->
    <section class="dash-cards">
      <article class="dash-card">
        <h3>Saldo</h3>
        <p class="dash-big">€ 20,00</p>
        <p class="dash-muted">Carteira do cliente (exemplo)</p>
      </article>

      <article class="dash-card">
        <h3>Encomendas</h3>
        <p class="dash-big">2</p>
        <p class="dash-muted">Encomendas feitas (exemplo)</p>
      </article>

      <article class="dash-card">
        <h3>Promoções</h3>
        <p class="dash-big">3</p>
        <p class="dash-muted">Ativas esta semana</p>
      </article>
    </section>

    <!-- Secção “últimas encomendas” (estrutura tipo tabela simples) -->
    <section class="dash-section">
      <div class="dash-section-top">
        <h3>Últimas encomendas</h3>
        <a href="#" class="link">Ver todas</a>
      </div>

      <div class="dash-table">
        <div class="row head">
          <div>ID</div><div>Estado</div><div>Total</div><div>Data</div>
        </div>
        <div class="row">
          <div>AB12CD34EF56</div><div>PAGA</div><div>€ 12,45</div><div>2026-03-19</div>
        </div>
        <div class="row">
          <div>XY98ZA12MN34</div><div>SUBMETIDA</div><div>€ 7,10</div><div>2026-03-18</div>
        </div>
      </div>
    </section>

  </main>

</div>


<!-- MODAL: Dados Pessoais -->
<div id="dadosModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>Dados Pessoais</h2>
      <a href="#" class="modal-close" id="fecharDadosLink">✕</a>
    </div>

    <form action="dados_pessoais_update.jsp" method="POST" class="login-form">
      <label for="nome">Nome</label>
      <input type="text" id="nome" name="nome" value="<%= nome %>" required>

      <label for="email">Email</label>
      <input type="email" id="email" name="email" value="<%= email %>">

      <label for="telefone">Telefone</label>
      <input type="text" id="telefone" name="telefone" value="<%= telefone %>">

      <label for="morada">Morada</label>
      <input type="text" id="morada" name="morada" value="<%= morada %>">

      <button type="submit" class="btn-submit">Guardar alterações</button>
    </form>

    <p class="modal-note">
      * Os dados são guardados na base de dados.
    </p>
  </div>
</div>

<script>
  const dadosModal = document.getElementById("dadosModal");
  const abrirDados = document.getElementById("abrirDadosLink");
  const fecharDados = document.getElementById("fecharDadosLink");

  abrirDados.addEventListener("click", function(e){
    e.preventDefault();
    dadosModal.classList.add("show");
  });

  fecharDados.addEventListener("click", function(e){
    e.preventDefault();
    dadosModal.classList.remove("show");
  });

  dadosModal.addEventListener("click", function(e){
    if(e.target.id === "dadosModal") dadosModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if(e.key === "Escape") dadosModal.classList.remove("show");
  });
</script>



<!-- MODAL: Consultar Produtos -->
<div id="produtosModal" class="modal">
  <div class="modal-box modal-wide">
    <div class="modal-top">
      <h2>Produtos disponíveis</h2>
      <a href="#" class="modal-close" id="fecharProdutosLink">✕</a>
    </div>

    <div class="produtos-modal-grid">
      <%
        if (rsP != null) {
          while (rsP.next()) {
            int id = rsP.getInt("id");
            String nomeP = rsP.getString("nome");
            String descP = rsP.getString("descricao");
            String catP = rsP.getString("categoria");
            double precoP = rsP.getDouble("preco");
      %>
            <article class="produto-card">
              <p class="produto-cat"><%= (catP != null ? catP : "Geral") %></p>
              <h3 class="produto-nome"><%= nomeP %></h3>
              <p class="produto-desc"><%= (descP != null ? descP : "") %></p>
              <div class="produto-footer">
                <span class="produto-preco"><%= String.format("%.2f €", precoP) %></span>
                <button class="btn-adicionar" type="button">Adicionar</button>
              </div>
            </article>
      <%
          }
        } else {
      %>
          <p>Não foi possível carregar os produtos.</p>
      <%
        }
      %>
    </div>
  </div>
</div>

<%-- Fechar recursos dos produtos (agora sim) --%>
<%
dbClose(rsP, psP, conP);
%>

<script id="fix-produtos-modal">
  const produtosModal = document.getElementById("produtosModal");
  const abrirProdutos = document.getElementById("abrirProdutosLink");
  const fecharProdutos = document.getElementById("fecharProdutosLink");

  if (abrirProdutos) {
    abrirProdutos.addEventListener("click", function(e){
      e.preventDefault();
      produtosModal.classList.add("show");
    });
  }

  if (fecharProdutos) {
    fecharProdutos.addEventListener("click", function(e){
      e.preventDefault();
      produtosModal.classList.remove("show");
    });
  }

  produtosModal.addEventListener("click", function(e){
    if (e.target.id === "produtosModal") produtosModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if (e.key === "Escape") produtosModal.classList.remove("show");
  });
</script>


<!-- MODAL: Gestão de Saldo -->
<div id="saldoModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>o seu dinheiro </h2>
      <a href="#" class="modal-close" id="fecharSaldoLink">✕</a>
    </div>

    <!-- Consultar -->
    <div class="saldo-box">
      <p class="saldo-label">Saldo atual</p>
      <p class="saldo-valor"><%= String.format("%.2f €", saldoAtual) %></p>
    </div>

    <!-- Adicionar saldo -->
    <form action="cliente_saldo.jsp" method="POST" class="saldo-form">
      <input type="hidden" name="acao" value="ADICIONAR">
      <label>Adicionar saldo (€)</label>
      <input type="number" name="valor" required>
      <button type="submit" class="btn-submit">Adicionar</button>
    </form>

    <!-- Levantar saldo -->
    <form action="cliente_saldo.jsp" method="POST" class="saldo-form">
      <input type="hidden" name="acao" value="LEVANTAR">
      <label>Levantar saldo (€)</label>
      <input type="number" name="valor" required>
      <button type="submit" class="btn-submit danger">Levantar</button>
    </form>

    <p class="modal-note">
      * As operações são registadas em auditoria (movimentos da carteira).
    </p>
  </div>
</div>

<script>
  const saldoModal = document.getElementById("saldoModal");
  const abrirSaldo = document.getElementById("abrirSaldoLink");
  const fecharSaldo = document.getElementById("fecharSaldoLink");

  if (abrirSaldo) {
    abrirSaldo.addEventListener("click", function(e){
      e.preventDefault();
      saldoModal.classList.add("show");
    });
  }
  if (fecharSaldo) {
    fecharSaldo.addEventListener("click", function(e){
      e.preventDefault();
      saldoModal.classList.remove("show");
    });
  }

  saldoModal.addEventListener("click", function(e){
    if(e.target.id === "saldoModal") saldoModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if(e.key === "Escape") saldoModal.classList.remove("show");
  });
</script>

</body>
</html>