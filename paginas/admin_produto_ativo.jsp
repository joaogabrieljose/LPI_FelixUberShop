<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String modo = request.getParameter("modo");
String idStr = request.getParameter("id");

if (modo == null || idStr == null || idStr.trim().isEmpty()) {
  response.sendRedirect("admin.jsp");
  return;
}

int id = Integer.parseInt(idStr);
int novoAtivo = "ATIVAR".equalsIgnoreCase(modo) ? 1 : 0;

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("UPDATE produtos SET ativo=? WHERE id=?");
  ps.setInt(1, novoAtivo);
  ps.setInt(2, id);
  dbUpdate(con, ps);
  response.sendRedirect("admin.jsp");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>