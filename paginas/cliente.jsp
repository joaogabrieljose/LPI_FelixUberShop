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


<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Dashboard Cliente - FelixUberShop</title>
  <link rel="stylesheet" href="cliente.css">
  <link rel="stylesheet" href="dados_pessoais.css">

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
      <a class="active" href="cliente.jsp">logout</a>
      <a href="#" id="abrirDadosLink">dados pessoais</a>
      <a href="#">Consultar produtos</a>
      <a href="#">Saldo</a>
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




</body>
</html>