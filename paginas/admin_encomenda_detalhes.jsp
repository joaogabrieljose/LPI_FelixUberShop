<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String idStr = request.getParameter("id");
String cod = request.getParameter("cod");

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

long encomendaId = 0;
String identificador = "";
String estado = "";
double total = 0.0;
String clienteUser = "";

try{
  con = dbConnect();

  if (idStr != null && !idStr.trim().isEmpty()) {
    encomendaId = Long.parseLong(idStr);
    ps = con.prepareStatement(
      "SELECT e.id, e.identificador, e.estado, e.total, u.username " +
      "FROM encomendas e JOIN utilizadores u ON u.id=e.cliente_id " +
      "WHERE e.id=? LIMIT 1"
    );
    ps.setLong(1, encomendaId);
  } else if (cod != null && !cod.trim().isEmpty()) {
    ps = con.prepareStatement(
      "SELECT e.id, e.identificador, e.estado, e.total, u.username " +
      "FROM encomendas e JOIN utilizadores u ON u.id=e.cliente_id " +
      "WHERE e.identificador=? LIMIT 1"
    );
    ps.setString(1, cod.trim());
  } else {
    response.sendRedirect("admin.jsp?enc=parametros");
    return;
  }

  rs = dbQuery(con, ps);
  if(!rs.next()){
    response.sendRedirect("admin.jsp?enc=nao_encontrada");
    return;
  }

  encomendaId = rs.getLong("id");
  identificador = rs.getString("identificador");
  estado = rs.getString("estado");
  total = rs.getDouble("total");
  clienteUser = rs.getString("username");

  dbClose(rs, ps, null);

  // itens
  ps = con.prepareStatement(
    "SELECT p.nome, ei.quantidade, ei.preco_unit, ei.subtotal " +
    "FROM encomenda_itens ei JOIN produtos p ON p.id=ei.produto_id " +
    "WHERE ei.encomenda_id=?"
  );
  ps.setLong(1, encomendaId);
  rs = dbQuery(con, ps);
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Admin - Encomenda <%= identificador %></title>
  <link rel="stylesheet" href="admin.css">
</head>
<body>
  <h2>Encomenda <%= identificador %></h2>
  <p><strong>Cliente:</strong> <%= clienteUser %></p>
  <p><strong>Estado:</strong> <%= estado %> | <strong>Total:</strong> <%= String.format("%.2f €", total) %></p>

  <p><a href="admin.jsp">← Voltar</a></p>

  <h3>Itens</h3>
  <div class="admin-table">
    <div class="row head">
      <div>Produto</div><div>Qtd</div><div>Preço</div><div>Subtotal</div>
    </div>

    <%
      boolean tem = false;
      while(rs.next()){
        tem = true;
    %>
      <div class="row" style="grid-template-columns: 1.4fr 0.4fr 0.6fr 0.6fr;">
        <div><%= rs.getString("nome") %></div>
        <div><%= rs.getInt("quantidade") %></div>
        <div><%= String.format("%.2f €", rs.getDouble("preco_unit")) %></div>
        <div><%= String.format("%.2f €", rs.getDouble("subtotal")) %></div>
      </div>
    <%
      }
      if(!tem){
    %>
      <div class="row"><div style="grid-column:1/-1;">Sem itens.</div></div>
    <%
      }
    %>
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