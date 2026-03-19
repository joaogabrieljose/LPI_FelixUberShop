<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%-- Restrição de acesso: apenas CLIENTE --%>
<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("CLIENTE")) {
    response.sendRedirect("index.jsp?acesso=negado");
    return;
}
String username = (String) session.getAttribute("username");
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Dashboard Cliente - FelixUberShop</title>
  <link rel="stylesheet" href="cliente.css">
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
    <a class="pill danger" href="logout.jsp">Logout</a>
  </div>
</header>

<div class="dash-layout">

  <!-- Menu lateral (usa o teu nav class="menu") -->
  <aside class="dash-side">
    <nav class="menu">
      <a class="active" href="cliente.jsp">Dashboard</a>
      <a href="#">Produtos</a>
      <a href="#">Promoções</a>
      <a href="#">Carrinho</a>
      <a href="#">Encomendas</a>
      <a href="#">Saldo / Carteira</a>
      <a href="#">Dados Pessoais</a>
      <a href="logout.jsp">Logout</a>
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

</body>
</html>