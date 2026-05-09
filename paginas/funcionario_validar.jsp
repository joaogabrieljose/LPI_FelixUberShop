<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer funcId = (Integer) session.getAttribute("userId");

if (perfil == null || funcId == null || !perfil.equalsIgnoreCase("FUNCIONARIO")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String cod = request.getParameter("cod");
if (cod == null || cod.trim().isEmpty()) {
  response.sendRedirect("funcionario.jsp?msg=cod_em_falta");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  ps = con.prepareStatement("SELECT id, estado FROM encomendas WHERE identificador=? LIMIT 1");
  ps.setString(1, cod.trim());
  rs = dbQuery(con, ps);

  if (!rs.next()) {
    con.rollback();
    response.sendRedirect("funcionario.jsp?msg=nao_encontrada");
    return;
  }

  long encId = rs.getLong("id");
  String estado = rs.getString("estado");
  dbClose(rs, ps, null);

  if (!"PAGA".equalsIgnoreCase(estado)) {
    con.rollback();
    response.sendRedirect("funcionario.jsp?msg=nao_pode_validar");
    return;
  }

  ps = con.prepareStatement(
    "UPDATE encomendas SET estado='VALIDADA', validada_por=?, validada_em=NOW() WHERE id=?"
  );
  ps.setInt(1, funcId);
  ps.setLong(2, encId);
  dbUpdate(con, ps);

  con.commit();
  response.sendRedirect("funcionario.jsp?msg=ok");
  return;

} catch(Exception e){
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>