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
if (encStr == null || itemStr == null) {
  response.sendRedirect("cliente.jsp?enc=parametros_em_falta");
  return;
}

long encomendaId = Long.parseLong(encStr);
long itemId = Long.parseLong(itemStr);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // confirmar encomenda do cliente e estado rascunho
  ps = con.prepareStatement("SELECT estado FROM encomendas WHERE id=? AND cliente_id=? LIMIT 1");
  ps.setLong(1, encomendaId);
  ps.setInt(2, userId);
  rs = dbQuery(con, ps);

  if (!rs.next() || !"RASCUNHO".equalsIgnoreCase(rs.getString("estado"))) {
    con.rollback();
    response.sendRedirect("cliente_encomenda_editar.jsp?id=" + encomendaId + "&erro=nao_editavel");
    return;
  }

  dbClose(rs, ps, null);

  // remover item
  ps = con.prepareStatement("DELETE FROM encomenda_itens WHERE id=? AND encomenda_id=?");
  ps.setLong(1, itemId);
  ps.setLong(2, encomendaId);
  dbUpdate(con, ps);
  dbClose(null, ps, null);

  // recalcular total
  ps = con.prepareStatement(
    "UPDATE encomendas SET total=(SELECT IFNULL(SUM(subtotal),0) FROM encomenda_itens WHERE encomenda_id=?) WHERE id=?"
  );
  ps.setLong(1, encomendaId);
  ps.setLong(2, encomendaId);
  dbUpdate(con, ps);

  con.commit();
  response.sendRedirect("cliente_encomenda_editar.jsp?id=" + encomendaId + "&ok=1");

} catch (Exception e) {
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>