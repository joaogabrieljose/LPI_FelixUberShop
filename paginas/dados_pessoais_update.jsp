<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userIdObj = (Integer) session.getAttribute("userId");

if (perfil == null || userIdObj == null) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

int userId = userIdObj.intValue();

/* de onde veio (para voltar certo) */
String from = request.getParameter("from"); // admin | funcionario | cliente
String redirectPage = "cliente.jsp"; // default

if ("admin".equalsIgnoreCase(from)) redirectPage = "admin.jsp";
else if ("funcionario".equalsIgnoreCase(from)) redirectPage = "funcionario.jsp";
else if ("cliente".equalsIgnoreCase(from)) redirectPage = "cliente.jsp";
else {
  // fallback pelo perfil da sessão
  if ("ADMIN".equalsIgnoreCase(perfil)) redirectPage = "admin.jsp";
  else if ("FUNCIONARIO".equalsIgnoreCase(perfil)) redirectPage = "funcionario.jsp";
  else redirectPage = "cliente.jsp";
}

/* inputs */
String nome = request.getParameter("nome");
String email = request.getParameter("email");
String telefone = request.getParameter("telefone");
String morada = request.getParameter("morada");

if (nome == null || nome.trim().isEmpty()) {
  response.sendRedirect(redirectPage + "?dp=erro_nome");
  return;
}

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();

  ps = con.prepareStatement(
    "UPDATE utilizadores SET nome=?, email=?, telefone=?, morada=? WHERE id=? LIMIT 1"
  );
  ps.setString(1, nome.trim());
  ps.setString(2, (email != null ? email.trim() : ""));
  ps.setString(3, (telefone != null ? telefone.trim() : ""));
  ps.setString(4, (morada != null ? morada.trim() : ""));
  ps.setInt(5, userId);

  int linhas = dbUpdate(con, ps);

  if (linhas > 0) {
    response.sendRedirect(redirectPage + "?dp=ok");
  } else {
    response.sendRedirect(redirectPage + "?dp=nao_alterou");
  }
  return;

} catch (Exception e) {
  response.sendRedirect(redirectPage + "?dp=erro");
  return;
} finally {
  dbClose(null, ps, con);
}
%>