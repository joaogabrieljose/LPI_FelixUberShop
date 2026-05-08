<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String username = request.getParameter("username");
String password = request.getParameter("password");
String perfilNovo = request.getParameter("perfil");
String ativoStr = request.getParameter("ativo");

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String telefone = request.getParameter("telefone");
String morada = request.getParameter("morada");

if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
  response.sendRedirect("admin.jsp?user=erro_campos");
  return;
}

int ativo = 1;
try { if (ativoStr != null) ativo = Integer.parseInt(ativoStr); } catch(Exception ig){}

if (perfilNovo == null || (!perfilNovo.equalsIgnoreCase("CLIENTE") && !perfilNovo.equalsIgnoreCase("ADMIN"))) {
  perfilNovo = "CLIENTE";
}

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();

  // validar duplicado
  ps = con.prepareStatement("SELECT id FROM utilizadores WHERE username=? LIMIT 1");
  ps.setString(1, username.trim());
  ResultSet rs = dbQuery(con, ps);
  if (rs.next()) {
    dbClose(rs, ps, con);
    response.sendRedirect("admin.jsp?user=ja_existe");
    return;
  }
  dbClose(rs, ps, null);

  ps = con.prepareStatement(
    "INSERT INTO utilizadores(username, password, perfil, ativo, nome, email, telefone, morada) " +
    "VALUES(?,?,?,?,?,?,?,?)"
  );
  ps.setString(1, username.trim());
  ps.setString(2, password); // (simples; se quiseres hash eu explico depois)
  ps.setString(3, perfilNovo.toUpperCase());
  ps.setInt(4, ativo);
  ps.setString(5, (nome!=null?nome:""));
  ps.setString(6, (email!=null?email:""));
  ps.setString(7, (telefone!=null?telefone:""));
  ps.setString(8, (morada!=null?morada:""));

  dbUpdate(con, ps);
  response.sendRedirect("admin.jsp?user=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>