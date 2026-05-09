<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
request.setCharacterEncoding("UTF-8");

String username = request.getParameter("username");
String password = request.getParameter("password");
String nome = request.getParameter("nome");
String email = request.getParameter("email");
String telefone = request.getParameter("telefone");
String morada = request.getParameter("morada");

// ✅ CORRIGIDO: voltar para index.jsp (modal) e não registar.jsp
if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
  response.sendRedirect("index.jsp?reg=campos");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();

  // 1) verificar duplicado
  ps = con.prepareStatement("SELECT id FROM utilizadores WHERE username=? LIMIT 1");
  ps.setString(1, username.trim());
  rs = dbQuery(con, ps);

  if (rs.next()) {
    dbClose(rs, ps, con);
    response.sendRedirect("index.jsp?reg=ja_existe");
    return;
  }
  dbClose(rs, ps, null);

  // 2) inserir como CLIENTE pendente (ativo=0)
  ps = con.prepareStatement(
    "INSERT INTO utilizadores(username, password, perfil, ativo, nome, email, telefone, morada) " +
    "VALUES(?,?,?,?,?,?,?,?)"
  );
  ps.setString(1, username.trim());
  ps.setString(2, password);
  ps.setString(3, "CLIENTE");
  ps.setInt(4, 0); // ✅ pendente para aprovação do admin
  ps.setString(5, nome != null ? nome : "");
  ps.setString(6, email != null ? email : "");
  ps.setString(7, telefone != null ? telefone : "");
  ps.setString(8, morada != null ? morada : "");

  dbUpdate(con, ps);

  // ✅ CORRIGIDO: voltar para index.jsp com sucesso
  response.sendRedirect("index.jsp?reg=ok");
  return;

} catch(Exception e) {
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>