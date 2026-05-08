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
String acao  = request.getParameter("acao"); // VALIDAR / CANCELAR

if (idStr == null || idStr.trim().isEmpty() || acao == null || acao.trim().isEmpty()) {
  response.sendRedirect("admin.jsp?enc=parametros");
  return;
}

long id;
try { id = Long.parseLong(idStr); }
catch(Exception e){
  response.sendRedirect("admin.jsp?enc=id_invalido");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // 1) Ler estado atual
  ps = con.prepareStatement("SELECT estado FROM encomendas WHERE id=? LIMIT 1");
  ps.setLong(1, id);
  rs = dbQuery(con, ps);

  if (!rs.next()) {
    con.rollback();
    response.sendRedirect("admin.jsp?enc=nao_encontrada");
    return;
  }

  String estadoAtual = rs.getString("estado");
  dbClose(rs, ps, null);

  // 2) Definir novo estado com regras (compatível com ENUM)
  String novoEstado = null;

  if ("VALIDAR".equalsIgnoreCase(acao)) {
    // Só valida se estiver PAGA
    if ("PAGA".equalsIgnoreCase(estadoAtual)) {
      novoEstado = "VALIDADA";

      // Guardar quem validou (opcional, tens campos na tabela)
      ps = con.prepareStatement(
        "UPDATE encomendas SET estado=?, validada_por=?, validada_em=NOW() WHERE id=?"
      );
      ps.setString(1, novoEstado);
      ps.setInt(2, (Integer) session.getAttribute("userId"));
      ps.setLong(3, id);

      dbUpdate(con, ps);
      con.commit();
      response.sendRedirect("admin_encomenda_detalhes.jsp?id=" + id + "&ok=1");
      return;

    } else {
      con.rollback();
      response.sendRedirect("admin_encomenda_detalhes.jsp?id=" + id + "&erro=nao_pode_validar");
      return;
    }
  }

  if ("CANCELAR".equalsIgnoreCase(acao)) {
    // Não cancelar se já estiver VALIDADA ou CANCELADA
    if ("VALIDADA".equalsIgnoreCase(estadoAtual) || "CANCELADA".equalsIgnoreCase(estadoAtual)) {
      con.rollback();
      response.sendRedirect("admin_encomenda_detalhes.jsp?id=" + id + "&erro=nao_pode_cancelar");
      return;
    }

    novoEstado = "CANCELADA";
    ps = con.prepareStatement("UPDATE encomendas SET estado=? WHERE id=?");
    ps.setString(1, novoEstado);
    ps.setLong(2, id);

    dbUpdate(con, ps);
    con.commit();
    response.sendRedirect("admin_encomenda_detalhes.jsp?id=" + id + "&ok=1");
    return;
  }

  // ação inválida
  con.rollback();
  response.sendRedirect("admin.jsp?enc=acao_invalida");

} catch (Exception e) {
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>