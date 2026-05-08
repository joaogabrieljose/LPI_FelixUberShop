<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer adminId = (Integer) session.getAttribute("userId");
if (perfil == null || adminId == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String modo = request.getParameter("modo"); // ATIVAR / INATIVAR
String idStr = request.getParameter("id");
if (modo == null || idStr == null) {
  response.sendRedirect("admin.jsp?user=erro");
  return;
}

int id = Integer.parseInt(idStr);
int novoAtivo = "ATIVAR".equalsIgnoreCase(modo) ? 1 : 0;

// não deixar o admin desativar a si mesmo
if (id == adminId && novoAtivo == 0) {
  response.sendRedirect("admin.jsp?user=nao_pode_desativar_si");
  return;
}

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("UPDATE utilizadores SET ativo=? WHERE id=?");
  ps.setInt(1, novoAtivo);
  ps.setInt(2, id);
  dbUpdate(con, ps);
  response.sendRedirect("admin.jsp?user=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>