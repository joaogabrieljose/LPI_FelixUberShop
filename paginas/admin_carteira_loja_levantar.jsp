<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer adminId = (Integer) session.getAttribute("userId");
if (perfil == null || adminId == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

String valorStr = request.getParameter("valor");
String descricao = request.getParameter("descricao");

if (valorStr == null || valorStr.trim().isEmpty()) {
  response.sendRedirect("admin_carteira_loja.jsp?msg=valor_em_falta");
  return;
}

double valor;
try { valor = Double.parseDouble(valorStr); }
catch(Exception e){ response.sendRedirect("admin_carteira_loja.jsp?msg=valor_invalido"); return; }

if (valor <= 0) { response.sendRedirect("admin_carteira_loja.jsp?msg=valor_invalido"); return; }

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // carteira LOJA
  ps = con.prepareStatement("SELECT id, saldo FROM carteiras WHERE tipo='LOJA' LIMIT 1");
  rs = dbQuery(con, ps);
  if (!rs.next()) {
    con.rollback();
    response.sendRedirect("admin_carteira_loja.jsp?msg=sem_carteira_loja");
    return;
  }
  int carteiraId = rs.getInt("id");
  double saldo = rs.getDouble("saldo");
  dbClose(rs, ps, null);

  if (saldo < valor) {
    con.rollback();
    response.sendRedirect("admin_carteira_loja.jsp?msg=saldo_insuficiente");
    return;
  }

  // atualizar saldo
  ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id=?");
  ps.setDouble(1, valor);
  ps.setInt(2, carteiraId);
  dbUpdate(con, ps);
  dbClose(null, ps, null);

  // auditoria (ENUM aceita: AJUSTE)
  String descFinal = (descricao != null && !descricao.trim().isEmpty())
    ? descricao.trim()
    : ("Levantamento na LOJA (AJUSTE) por ADMIN id=" + adminId);

  ps = con.prepareStatement(
    "INSERT INTO movimentos_carteira(tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao) " +
    "VALUES(?, ?, ?, NULL, ?)"
  );
  ps.setString(1, "AJUSTE");   
  ps.setDouble(2, valor);
  ps.setInt(3, carteiraId);
  ps.setString(4, descFinal);
  dbUpdate(con, ps);

  con.commit();
  response.sendRedirect("admin_carteira_loja.jsp?msg=ok");
  return;

} catch(Exception e){
  try { if (con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>