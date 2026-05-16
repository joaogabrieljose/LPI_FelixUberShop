<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer funcIdObj = (Integer) session.getAttribute("userId");

if (perfil == null || funcIdObj == null || !perfil.equalsIgnoreCase("FUNCIONARIO")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

int funcId = funcIdObj.intValue();

String idStr = request.getParameter("id");
if (idStr == null || idStr.trim().isEmpty()) {
  response.sendRedirect("funcionario.jsp?msg=codigo_em_falta");
  return;
}

long encomendaId;
try {
  encomendaId = Long.parseLong(idStr.trim());
} catch(Exception e) {
  response.sendRedirect("funcionario.jsp?msg=id_invalido");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();

  //  Confirmar estado atual
  ps = con.prepareStatement("SELECT estado FROM encomendas WHERE id=? LIMIT 1");
  ps.setLong(1, encomendaId);
  rs = dbQuery(con, ps);

  if (!rs.next()) {
    response.sendRedirect("funcionario.jsp?msg=nao_encontrada");
    return;
  }

  String estado = rs.getString("estado");
  dbClose(rs, ps, null);

  if (!"PAGA".equalsIgnoreCase(estado)) {
    response.sendRedirect("funcionario.jsp?msg=nao_pode_validar");
    return;
  }

  // 2) Validar (igual ao admin)
  ps = con.prepareStatement(
    "UPDATE encomendas " +
    "SET estado='VALIDADA', validada_por=?, validada_em=NOW() " +
    "WHERE id=? AND estado='PAGA'"
  );
  ps.setInt(1, funcId);
  ps.setLong(2, encomendaId);

  int rows = dbUpdate(con, ps);

  if (rows == 0) {
    response.sendRedirect("funcionario.jsp?msg=nao_pode_validar");
  } else {
    response.sendRedirect("funcionario.jsp?msg=ok");
  }
  return;

} catch(Exception e) {
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>