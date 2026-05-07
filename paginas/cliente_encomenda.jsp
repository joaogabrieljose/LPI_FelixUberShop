<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");
if (perfil == null || userId == null || !perfil.equalsIgnoreCase("CLIENTE")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String encStr  = request.getParameter("encomenda_id");
String prodStr = request.getParameter("produto_id");
String qtdStr  = request.getParameter("quantidade");

if (encStr == null || prodStr == null || qtdStr == null ||
    encStr.trim().isEmpty() || prodStr.trim().isEmpty() || qtdStr.trim().isEmpty()) {
  response.sendRedirect("cliente.jsp?enc=parametros_em_falta");
  return;
}

long encomendaId;
int produtoId;
int qtd;

try {
  encomendaId = Long.parseLong(encStr);
  produtoId   = Integer.parseInt(prodStr);
  qtd         = Integer.parseInt(qtdStr);
} catch(Exception ex) {
  response.sendRedirect("cliente.jsp?enc=parametros_invalidos");
  return;
}

if (qtd <= 0) {
  response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&erro=qtd");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  //  validar encomenda do cliente e estado RASCUNHO
  ps = con.prepareStatement("SELECT estado FROM encomendas WHERE id=? AND cliente_id=? LIMIT 1");
  ps.setLong(1, encomendaId);
  ps.setInt(2, userId);
  rs = dbQuery(con, ps);

  if (!rs.next()) {
    con.rollback();
    response.sendRedirect("cliente.jsp?enc=inexistente");
    return;
  }

  String estado = rs.getString("estado");
  dbClose(rs, ps, null);

  if (!"RASCUNHO".equalsIgnoreCase(estado)) {
    con.rollback();
    response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&erro=nao_editavel");
    return;
  }

  //  buscar preço do produto (ativo)
  ps = con.prepareStatement("SELECT preco FROM produtos WHERE id=? AND ativo=1 LIMIT 1");
  ps.setInt(1, produtoId);
  rs = dbQuery(con, ps);

  if (!rs.next()) {
    con.rollback();
    response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&erro=produto");
    return;
  }

  double preco = rs.getDouble("preco");
  dbClose(rs, ps, null);

  //  se já existe item (mesmo produto) -> UPDATE (somar quantidade)
  ps = con.prepareStatement(
    "SELECT id, quantidade FROM encomenda_itens WHERE encomenda_id=? AND produto_id=? LIMIT 1"
  );
  ps.setLong(1, encomendaId);
  ps.setInt(2, produtoId);
  rs = dbQuery(con, ps);

  if (rs.next()) {
    long itemId = rs.getLong("id");
    int qtdAtual = rs.getInt("quantidade");
    int novaQtd = qtdAtual + qtd;
    double novoSubtotal = novaQtd * preco;

    dbClose(rs, ps, null);

    ps = con.prepareStatement("UPDATE encomenda_itens SET quantidade=?, preco_unit=?, subtotal=? WHERE id=?");
    ps.setInt(1, novaQtd);
    ps.setDouble(2, preco);
    ps.setDouble(3, novoSubtotal);
    ps.setLong(4, itemId);
    dbUpdate(con, ps);
    dbClose(null, ps, null);

  } else {
    dbClose(rs, ps, null);

    double subtotal = preco * qtd;

    ps = con.prepareStatement(
      "INSERT INTO encomenda_itens(encomenda_id, produto_id, quantidade, preco_unit, subtotal) VALUES(?,?,?,?,?)"
    );
    ps.setLong(1, encomendaId);
    ps.setInt(2, produtoId);
    ps.setInt(3, qtd);
    ps.setDouble(4, preco);
    ps.setDouble(5, subtotal);
    dbUpdate(con, ps);
    dbClose(null, ps, null);
  }

  //  recalcular total da encomenda
  ps = con.prepareStatement(
    "UPDATE encomendas SET total=(SELECT IFNULL(SUM(subtotal),0) FROM encomenda_itens WHERE encomenda_id=?) WHERE id=?"
  );
  ps.setLong(1, encomendaId);
  ps.setLong(2, encomendaId);
  dbUpdate(con, ps);

  con.commit();

  // voltar para a página de detalhes para veres a atualização
  response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&ok=1");
  return;

} catch(Exception e) {
  try { if (con != null) con.rollback(); } catch(Exception ig) {}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>