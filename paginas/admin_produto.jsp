<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String nome = request.getParameter("nome");
String descricao = request.getParameter("descricao");
String categoria = request.getParameter("categoria");
String precoStr = request.getParameter("preco");

if (nome == null || nome.trim().isEmpty() || precoStr == null || precoStr.trim().isEmpty()) {
  response.sendRedirect("admin.jsp?prod=erro");
  return;
}

double preco = Double.parseDouble(precoStr);

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("INSERT INTO produtos(nome, descricao, categoria, preco, ativo) VALUES(?,?,?,?,1)");
  ps.setString(1, nome.trim());
  ps.setString(2, (descricao != null ? descricao.trim() : ""));
  ps.setString(3, (categoria != null ? categoria.trim() : ""));
  ps.setDouble(4, preco);
  dbUpdate(con, ps);

  response.sendRedirect("admin.jsp?prod=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>