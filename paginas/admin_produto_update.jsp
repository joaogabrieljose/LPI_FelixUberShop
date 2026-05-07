<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String idStr = request.getParameter("id");
String nome = request.getParameter("nome");
String categoria = request.getParameter("categoria");
String precoStr = request.getParameter("preco");

if (idStr == null || nome == null || nome.trim().isEmpty() || precoStr == null) {
  response.sendRedirect("admin.jsp?prod=erro");
  return;
}

int id = Integer.parseInt(idStr);
double preco = Double.parseDouble(precoStr);

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("UPDATE produtos SET nome=?, categoria=?, preco=? WHERE id=?");
  ps.setString(1, nome.trim());
  ps.setString(2, (categoria != null ? categoria.trim() : ""));
  ps.setDouble(3, preco);
  ps.setInt(4, id);
  dbUpdate(con, ps);

  response.sendRedirect("admin.jsp?prod=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>