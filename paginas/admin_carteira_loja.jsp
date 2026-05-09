<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer adminId = (Integer) session.getAttribute("userId");
String username = (String) session.getAttribute("username");

if (perfil == null || adminId == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String msg = request.getParameter("msg"); // ok / erro / saldo_insuficiente

// 1) carteira LOJA
int carteiraLojaId = 0;
double saldoLoja = 0.0;

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("SELECT id, saldo FROM carteiras WHERE tipo='LOJA' LIMIT 1");
  rs = dbQuery(con, ps);

  if (rs.next()) {
    carteiraLojaId = rs.getInt("id");
    saldoLoja = rs.getDouble("saldo");
  }
  dbClose(rs, ps, null);

  // 2) movimentos da loja
  ps = con.prepareStatement(
    "SELECT tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao, criado_em " +
    "FROM movimentos_carteira " +
    "WHERE carteira_origem_id=? OR carteira_destino_id=? " +
    "ORDER BY criado_em DESC LIMIT 50"
  );
  ps.setInt(1, carteiraLojaId);
  ps.setInt(2, carteiraLojaId);
  rs = dbQuery(con, ps);
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Carteira da Loja - Admin</title>
  <link rel="stylesheet" href="admin.css">
</head>
<body>

<header class="dash-top">
  <div class="dash-brand">
    <a class="brand" href="admin.jsp">
      <img src="legumes.png" class="logo" alt="FelixUberShop">
    </a>
    <div>
      <h1>FelixUberShop</h1>
      <p>Carteira da Loja (Admin)</p>
    </div>
  </div>

  <div class="dash-user">
    <span class="pill">🛠️ <%= username %></span>
    <a class="pill" href="logout.jsp">Logout</a>
  </div>
</header>

<div class="dash-layout">
  <aside class="dash-side">
    <nav class="menu">
      <a href="admin.jsp">Dashboard</a>
      <a href="admin.jsp">Gerir Produtos</a>
      <a href="admin.jsp">Gerir Promoções</a>
      <a href="admin.jsp">Gerir Encomendas</a>
      <a href="admin.jsp">Gerir Utilizadores</a>
      <a class="active" href="admin_carteira_loja.jsp">Carteira da Loja</a>
      <a href="logout.jsp">Logout</a>
    </nav>
  </aside>

  <main class="dash-main">

    <section class="dash-hero">
      <h2>Saldo da Loja</h2>
      <p class="muted">Carteira tipo <strong>LOJA</strong>. Aqui podes consultar saldo, movimentos e fazer ajustes (com auditoria).</p>

      <% if (msg != null) { %>
        <p style="font-weight:900; color:<%= "ok".equals(msg) ? "green" : "red" %>;">
          <%= "ok".equals(msg) ? "Operação realizada com sucesso." : ("Erro: " + msg) %>
        </p>
      <% } %>

      <div class="dash-cards" style="margin-top:12px;">
        <article class="dash-card">
          <h3>Saldo Atual</h3>
          <p class="dash-big"><%= String.format("€ %.2f", saldoLoja) %></p>
          <p class="dash-muted">ID carteira: <%= carteiraLojaId %></p>
        </article>
      </div>
    </section>

    <section class="dash-section">
      <h3>Ajustar saldo (Admin)</h3>
      <p class="muted">Use apenas para testes. Todas as operações ficam registadas em <code>movimentos_carteira</code>.</p>

      <div class="estado-actions">
      <!-- DEPOSITAR -->
        <form action="admin_carteira_loja_depositar.jsp" method="POST" class="saldo-form">
        <label>Depositar (€)</label>
        <input type="number" name="valor" step="0.01" min="0.01" required>
        <button type="submit" class="btn-submit">Depositar</button>
        </form>

        <!-- LEVANTAR -->
        <form action="admin_carteira_loja_levantar.jsp" method="POST" class="saldo-form">
        <label>Levantar (€)</label>
        <input type="number" name="valor" step="0.01" min="0.01" required>
        <button type="submit" class="btn-submit danger">Levantar</button>
        </form>
      </div>
    </section>

    <section class="dash-section">
      <div class="dash-section-top">
        <h3>Movimentos (últimos 50)</h3>
      </div>

      <div class="admin-table">
        <div class="row head">
          <div>Data</div><div>Tipo</div><div>Valor</div><div>Origem</div><div>Destino</div><div>Descrição</div>
        </div>

        <%
          boolean temMov = false;
          while (rs.next()) {
            temMov = true;
            Timestamp dt = rs.getTimestamp("criado_em");
            String tipo = rs.getString("tipo_operacao");
            double val = rs.getDouble("valor");
            int orig = rs.getInt("carteira_origem_id");
            int dest = rs.getInt("carteira_destino_id");
            String desc = rs.getString("descricao");
        %>
          <div class="row" style="grid-template-columns: 0.9fr 0.9fr 0.6fr 0.6fr 0.6fr 1.4fr;">
            <div><%= (dt != null ? dt.toString().substring(0,16) : "") %></div>
            <div><%= tipo %></div>
            <div><%= String.format("€ %.2f", val) %></div>
            <div><%= orig %></div>
            <div><%= dest %></div>
            <div><%= (desc != null ? desc : "") %></div>
          </div>
        <%
          }
          if (!temMov) {
        %>
          <div class="row"><div style="grid-column:1/-1;">Sem movimentos.</div></div>
        <%
          }
        %>
      </div>
    </section>

  </main>
</div>

</body>
</html>

<%
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>