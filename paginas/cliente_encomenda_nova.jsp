<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");

if (perfil == null || userId == null || !perfil.equalsIgnoreCase("CLIENTE")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // 1) gerar identificador único (12 chars alfanuméricos)
  String cod = java.util.UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase();

  // 2) garantir que não existe igual (muito raro, mas seguro)
  ps = con.prepareStatement("SELECT id FROM encomendas WHERE identificador=? LIMIT 1");
  ps.setString(1, cod);
  rs = dbQuery(con, ps);

  if (rs.next()) {
    // se por azar existir, gera outro
    cod = java.util.UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase();
  }
  dbClose(rs, ps, null);

  // 3) inserir encomenda em RASCUNHO
  ps = con.prepareStatement(
    "INSERT INTO encomendas(identificador, cliente_id, estado, total) VALUES(?, ?, 'RASCUNHO', 0.00)",
    Statement.RETURN_GENERATED_KEYS
  );
  ps.setString(1, cod);
  ps.setInt(2, userId);
  dbUpdate(con, ps);

  // 4) obter o ID gerado (para usar internamente)
  rs = ps.getGeneratedKeys();
  long encomendaId = 0;
  if (rs.next()) encomendaId = rs.getLong(1);

  con.commit();

  // 5) redirecionar para detalhes/editar
  response.sendRedirect("cliente_encomenda_detalhes.jsp?id=" + encomendaId + "&nova=1");
  return;

} catch (Exception e) {
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro ao criar encomenda: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>