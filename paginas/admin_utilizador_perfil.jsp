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

String idStr = request.getParameter("id");
String novoPerfil = request.getParameter("perfil");

if (idStr == null || novoPerfil == null) {
  response.sendRedirect("admin.jsp?user=erro");
  return;
}

int id = Integer.parseInt(idStr);
novoPerfil = novoPerfil.toUpperCase();

if (!novoPerfil.equals("CLIENTE") && !novoPerfil.equals("ADMIN")) {
  response.sendRedirect("admin.jsp?user=perfil_invalido");
  return;
}

// impedir que o admin se remova a si próprio como admin
if (id == adminId && novoPerfil.equals("CLIENTE")) {
  response.sendRedirect("admin.jsp?user=nao_pode_retirar_admin");
  return;
}

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("UPDATE utilizadores SET perfil=? WHERE id=?");
  ps.setString(1, novoPerfil);
  ps.setInt(2, id);
  dbUpdate(con, ps);
  response.sendRedirect("admin.jsp?user=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>