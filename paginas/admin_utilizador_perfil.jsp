<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String sessPerfil = (String) session.getAttribute("perfil");
Integer sessUserId = (Integer) session.getAttribute("userId");

String BASE = request.getContextPath() + "/paginas/";

// só ADMIN oficial (ID=4)
if (sessPerfil == null || sessUserId == null || !sessPerfil.equalsIgnoreCase("ADMIN") || sessUserId.intValue() != 4) {
  response.sendRedirect(BASE + "index.jsp?acesso=negado");
  return;
}

String idStr = request.getParameter("id");
String novoPerfil = request.getParameter("perfil"); // CLIENTE | FUNCIONARIO | ADMIN

if (idStr == null || idStr.trim().isEmpty() || novoPerfil == null || novoPerfil.trim().isEmpty()) {
  response.sendRedirect(BASE + "admin.jsp?u=erro_campos");
  return;
}

int alvoId;
try { alvoId = Integer.parseInt(idStr.trim()); }
catch(Exception e){ response.sendRedirect(BASE + "admin.jsp?u=erro_id"); return; }

// não deixar mudar o admin oficial (ID=4)
if (alvoId == 4) {
  response.sendRedirect(BASE + "admin.jsp?u=nao_pode_mudar_admin_oficial");
  return;
}

// normalizar
novoPerfil = novoPerfil.trim().toUpperCase();

// validar valores permitidos
if (!(novoPerfil.equals("CLIENTE") || novoPerfil.equals("FUNCIONARIO") || novoPerfil.equals("ADMIN"))) {
  response.sendRedirect(BASE + "admin.jsp?u=perfil_invalido");
  return;
}

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement("UPDATE utilizadores SET perfil=? WHERE id=?");
  ps.setString(1, novoPerfil);
  ps.setInt(2, alvoId);

  int rows = dbUpdate(con, ps);

  if (rows == 0) {
    response.sendRedirect(BASE + "admin.jsp?u=nao_encontrado");
  } else {
    response.sendRedirect(BASE + "admin.jsp?u=perfil_ok");
  }
  return;

} catch(Exception e) {
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>