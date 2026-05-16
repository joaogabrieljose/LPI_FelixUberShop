<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String BASE = request.getContextPath() + "/paginas/";

String sessPerfil = (String) session.getAttribute("perfil");
Integer sessUserId = (Integer) session.getAttribute("userId");

if (sessPerfil == null || sessUserId == null || !sessPerfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect(BASE + "index.jsp?acesso=negado");
  return;
}

String idStr = request.getParameter("id");
String username = request.getParameter("username");
String password = request.getParameter("password");
String perfilNovo = request.getParameter("perfil"); // CLIENTE | FUNCIONARIO | ADMIN
String ativoStr = request.getParameter("ativo");

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String telefone = request.getParameter("telefone");
String morada = request.getParameter("morada");

if (idStr == null || idStr.trim().isEmpty() ||
    username == null || username.trim().isEmpty() ||
    password == null || password.trim().isEmpty()) {
  response.sendRedirect(BASE + "admin.jsp?user=erro_campos");
  return;
}

int novoId;
try { novoId = Integer.parseInt(idStr.trim()); }
catch(Exception e){ response.sendRedirect(BASE + "admin.jsp?user=erro_id"); return; }

int ativo = 1;
try { if (ativoStr != null) ativo = Integer.parseInt(ativoStr); } catch(Exception ig){}

perfilNovo = (perfilNovo == null ? "CLIENTE" : perfilNovo.trim().toUpperCase());
if (!(perfilNovo.equals("CLIENTE") || perfilNovo.equals("FUNCIONARIO") || perfilNovo.equals("ADMIN"))) {
  perfilNovo = "CLIENTE";
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // 1) evitar ID duplicado
  ps = con.prepareStatement("SELECT id FROM utilizadores WHERE id=? LIMIT 1");
  ps.setInt(1, novoId);
  rs = ps.executeQuery();
  if (rs.next()) {
    con.rollback();
    response.sendRedirect(BASE + "admin.jsp?user=id_ja_existe");
    return;
  }
  dbClose(rs, ps, null);

  // 2) evitar username duplicado
  ps = con.prepareStatement("SELECT id FROM utilizadores WHERE username=? LIMIT 1");
  ps.setString(1, username.trim());
  rs = ps.executeQuery();
  if (rs.next()) {
    con.rollback();
    response.sendRedirect(BASE + "admin.jsp?user=ja_existe");
    return;
  }
  dbClose(rs, ps, null);

  // 3) criar utilizador (ID manual)
  ps = con.prepareStatement(
    "INSERT INTO utilizadores(id, username, password, perfil, ativo, nome, email, telefone, morada) " +
    "VALUES(?,?,?,?,?,?,?,?,?)"
  );
  ps.setInt(1, novoId);
  ps.setString(2, username.trim());
  ps.setString(3, password);
  ps.setString(4, perfilNovo);
  ps.setInt(5, ativo);
  ps.setString(6, (nome!=null?nome:""));
  ps.setString(7, (email!=null?email:""));
  ps.setString(8, (telefone!=null?telefone:""));
  ps.setString(9, (morada!=null?morada:""));
  ps.executeUpdate();
  dbClose(null, ps, null);

  // 4) criar carteira UTILIZADOR (saldo inicial 0.00)
  ps = con.prepareStatement(
    "INSERT INTO carteiras(utilizador_id, tipo, saldo) VALUES(?, 'UTILIZADOR', 0.00)"
  );
  ps.setInt(1, novoId);
  ps.executeUpdate();
  dbClose(null, ps, null);

  con.commit();
  response.sendRedirect(BASE + "admin.jsp?user=ok");
  return;

} catch(Exception e){
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  try { if (con != null) con.setAutoCommit(true); } catch(Exception ig){}
  dbClose(rs, ps, con);
}
%>