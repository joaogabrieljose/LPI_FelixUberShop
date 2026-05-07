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

String idStr = request.getParameter("id");
if (idStr == null || idStr.trim().isEmpty()) {
  response.sendRedirect("cliente.jsp?enc=id_em_falta");
  return;
}

long encomendaId;
try { encomendaId = Long.parseLong(idStr); }
catch(Exception ex){ response.sendRedirect("cliente.jsp?enc=id_invalido"); return; }

String ok = request.getParameter("ok");
String erro = request.getParameter("erro");

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

PreparedStatement psProd = null;
ResultSet rsProd = null;

String codigo = "";
String estado = "";
double total = 0.0;

try {
  con = dbConnect();

  // 1) Ver encomenda
  ps = con.prepareStatement(
    "SELECT identificador, estado, total FROM encomendas WHERE id=? AND cliente_id=? LIMIT 1"
  );
  ps.setLong(1, encomendaId);
  ps.setInt(2, userId);
  rs = dbQuery(con, ps);

  if (!rs.next()) {
    response.sendRedirect("cliente.jsp?enc=inexistente");
    return;
  }

  codigo = rs.getString("identificador");
  estado = rs.getString("estado");
  total  = rs.getDouble("total");

  dbClose(rs, ps, null);

  // 2) Lista de produtos (para o select)
  psProd = con.prepareStatement(
    "SELECT id, nome, preco FROM produtos WHERE ativo=1 ORDER BY nome"
  );
  rsProd = dbQuery(con, psProd);

  // 3) Itens da encomenda
  ps = con.prepareStatement(
    "SELECT ei.id AS item_id, p.nome, ei.quantidade, ei.preco_unit, ei.subtotal " +
    "FROM encomenda_itens ei JOIN produtos p ON p.id=ei.produto_id " +
    "WHERE ei.encomenda_id=? ORDER BY ei.id DESC"
  );
  ps.setLong(1, encomendaId);
  rs = dbQuery(con, ps);
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Encomenda <%= codigo %> - Detalhes</title>
  <link rel="stylesheet" href="cliente.css">
</head>
<body>

  <h2>Encomenda <%= codigo %></h2>

  <p>
    <strong>Estado:</strong> <%= estado %> |
    <strong>Total:</strong> <%= String.format("%.2f €", total) %>
  </p>

  <p><a href="cliente.jsp">← Voltar ao Dashboard</a></p>

  <% if ("1".equals(ok)) { %>
    <p style="color:green; font-weight:700;">Operação realizada com sucesso.</p>
  <% } %>

  <% if (erro != null) { %>
    <p style="color:red; font-weight:700;">Ocorreu um erro: <%= erro %></p>
  <% } %>

  <h3>Itens</h3>

  <div class="dash-table">
    <div class="row head">
      <div>Produto</div><div>Qtd</div><div>Preço</div><div>Subtotal</div><div>Ações</div>
    </div>

    <%
      boolean tem = false;
      while (rs.next()) {
        tem = true;
        long itemId = rs.getLong("item_id");
    %>
      <div class="row">
        <div><%= rs.getString("nome") %></div>
        <div><%= rs.getInt("quantidade") %></div>
        <div><%= String.format("%.2f €", rs.getDouble("preco_unit")) %></div>
        <div><%= String.format("%.2f €", rs.getDouble("subtotal")) %></div>

        <div>
          <% if ("RASCUNHO".equalsIgnoreCase(estado)) { %>
            <form action="cliente_encomenda_remove.jsp" method="POST" style="display:inline;">
              <input type="hidden" name="encomenda_id" value="<%= encomendaId %>">
              <input type="hidden" name="item_id" value="<%= itemId %>">
              <button type="submit">Remover</button>
            </form>
          <% } else { %>
            —
          <% } %>
        </div>
      </div>
    <%
      }

      if (!tem) {
    %>
      <div class="row">
        <div style="grid-column:1/-1;">
          <% if ("RASCUNHO".equalsIgnoreCase(estado)) { %>
            <br><small>Adicione produtos abaixo para começar.</small>
          <% } %>
        </div>
      </div>
    <%
      }
    %>
  </div>

  <% if ("RASCUNHO".equalsIgnoreCase(estado)) { %>
    <h3>Adicionar produto</h3>
    <p><small>Escolha o produto e indique a quantidade.</small></p>

    <form action="cliente_encomenda.jsp" method="POST">
      <input type="hidden" name="encomenda_id" value="<%= encomendaId %>">

      <label>Produto</label>
      <select name="produto_id" required>
        <%
          while (rsProd != null && rsProd.next()) {
        %>
          <option value="<%= rsProd.getInt("id") %>">
            <%= rsProd.getString("nome") %> — <%= String.format("%.2f €", rsProd.getDouble("preco")) %>
          </option>
        <%
          }
        %>
      </select>

      <label>Quantidade</label>
      <input type="number" name="quantidade" min="1" value="1" required>

      <button type="submit">Adicionar</button>
    </form>

  <% } else { %>
    <p><small>Esta encomenda não pode ser editada porque já não está em RASCUNHO.</small></p>
  <% } %>

</body>
</html>

<%
} catch (Exception e) {
  out.print("Erro: " + e.getMessage());
} finally {
  // fecha tudo
  dbClose(rs, ps, null);
  dbClose(rsProd, psProd, con);
}
%>