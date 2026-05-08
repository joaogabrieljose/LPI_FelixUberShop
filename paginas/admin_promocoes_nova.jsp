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

String titulo = request.getParameter("titulo");
String descricao = request.getParameter("descricao");
String descontoStr = request.getParameter("desconto_percent");
String ativaStr = request.getParameter("ativa");
String diStr = request.getParameter("data_inicio");
String dfStr = request.getParameter("data_fim");

if (titulo == null || titulo.trim().isEmpty() || descricao == null || descricao.trim().isEmpty()) {
  response.sendRedirect("admin.jsp?promo=erro_campos");
  return;
}

Integer desconto = null;
try { if (descontoStr != null && !descontoStr.trim().isEmpty()) desconto = Integer.parseInt(descontoStr); }
catch(Exception ig){ desconto = null; }

int ativa = 1; // default da tabela
try { if (ativaStr != null) ativa = Integer.parseInt(ativaStr); } catch(Exception ig){}

java.sql.Date di = null;
java.sql.Date df = null;
try { if (diStr != null && !diStr.isEmpty()) di = java.sql.Date.valueOf(diStr); } catch(Exception ig){}
try { if (dfStr != null && !dfStr.isEmpty()) df = java.sql.Date.valueOf(dfStr); } catch(Exception ig){}

Connection con = null;
PreparedStatement ps = null;

try {
  con = dbConnect();
  ps = con.prepareStatement(
    "INSERT INTO promocoes(titulo, descricao, desconto_percent, data_inicio, data_fim, ativa, criado_por) " +
    "VALUES(?,?,?,?,?,?,?)"
  );
  ps.setString(1, titulo.trim());
  ps.setString(2, descricao.trim());

  if (desconto == null) ps.setNull(3, java.sql.Types.INTEGER);
  else ps.setInt(3, desconto);

  if (di == null) ps.setNull(4, java.sql.Types.DATE); else ps.setDate(4, di);
  if (df == null) ps.setNull(5, java.sql.Types.DATE); else ps.setDate(5, df);

  ps.setInt(6, ativa);
  ps.setInt(7, userId);

  dbUpdate(con, ps);
  response.sendRedirect("admin.jsp?promo=ok");
} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(null, ps, con);
}
%>