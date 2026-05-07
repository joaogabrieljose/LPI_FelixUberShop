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

String encStr = request.getParameter("encomenda_id");
String itemStr = request.getParameter("item_id");

if (encStr == null || itemStr == null || encStr.trim().isEmpty() || itemStr.trim().isEmpty()) {
  response.sendRedirect("cliente.jsp?enc=parametros_em_falta");
  return;
}

long encomendaId;
long itemId;
try {
  encomendaId = Long.parseLong(encStr);
  itemId = Long.parseLong(itemStr);
} catch(Exception e){
  response.sendRedirect("cliente.jsp?enc=parametros_invalidos");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // 1) validar encomenda do cliente e estado RASCUNHO
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

  // 2) remover item (garantindo que pertence à encomenda)
  ps = con.prepareStatement("DELETE FROM encomenda_itens WHERE id=? AND encomenda_id=?");
  ps.setLong(1, itemId);
  ps.setLong(2, encomendaId);
  int linhas = dbUpdate(con, ps);
  dbClose(null, ps, null);

  if (linhas == 0) {
    con.rollback();
    response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&erro=item_nao_encontrado");
    return;
  }

  // 3) atualizar total da encomenda
  ps = con.prepareStatement(
    "UPDATE encomendas SET total=(SELECT IFNULL(SUM(subtotal),0) FROM encomenda_itens WHERE encomenda_id=?) WHERE id=?"
  );
  ps.setLong(1, encomendaId);
  ps.setLong(2, encomendaId);
  dbUpdate(con, ps);

  con.commit();
  response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&ok=1");
  return;

} catch(Exception e){
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>