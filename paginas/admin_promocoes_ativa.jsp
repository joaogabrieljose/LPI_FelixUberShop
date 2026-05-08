<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");

if (perfil == null || userId == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String idStr = request.getParameter("id");
String modo = request.getParameter("modo"); // ATIVAR / DESATIVAR

if (idStr == null || idStr.trim().isEmpty() || modo == null) {
  response.sendRedirect("admin.jsp?promo=erro");
  return;
}

int id = Integer.parseInt(idStr);
int ativa = "ATIVAR".equalsIgnoreCase(modo) ? 1 : 0;

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("UPDATE promocoes SET ativa=? WHERE id=?");
  ps.setInt(1, ativa);
  ps.setInt(2, id);
  dbUpdate(con, ps);

  response.sendRedirect("admin.jsp?promo=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>