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

String idStr = request.getParameter("id");
if (idStr == null || idStr.trim().isEmpty()) {
  response.sendRedirect("cliente.jsp?pagamento=erro_id");
  return;
}

long encomendaId;
try { encomendaId = Long.parseLong(idStr); }
catch(Exception e){ response.sendRedirect("cliente.jsp?pagamento=erro_id"); return; }

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try{
  con = dbConnect();
  con.setAutoCommit(false);

  // 1) validar encomenda do cliente e estado
  ps = con.prepareStatement("SELECT estado, total FROM encomendas WHERE id=? AND cliente_id=? LIMIT 1");
  ps.setLong(1, encomendaId);
  ps.setInt(2, userId);
  rs = dbQuery(con, ps);

  if(!rs.next()){
    con.rollback();
    response.sendRedirect("cliente.jsp?pagamento=encomenda_inexistente");
    return;
  }

  String estado = rs.getString("estado");
  double total = rs.getDouble("total");
  dbClose(rs, ps, null);

  if(!"RASCUNHO".equalsIgnoreCase(estado) || total <= 0){
    con.rollback();
    response.sendRedirect("cliente.jsp?pagamento=nao_permitido");
    return;
  }

  // 2) carteira do cliente
  ps = con.prepareStatement("SELECT id, saldo FROM carteiras WHERE utilizador_id=? AND tipo='UTILIZADOR' LIMIT 1");
  ps.setInt(1, userId);
  rs = dbQuery(con, ps);

  if(!rs.next()){
    con.rollback();
    response.sendRedirect("cliente.jsp?pagamento=sem_carteira");
    return;
  }

  int carteiraClienteId = rs.getInt("id");
  double saldoCliente = rs.getDouble("saldo");
  dbClose(rs, ps, null);

  if(saldoCliente < total){
    con.rollback();
    response.sendRedirect("cliente.jsp?pagamento=saldo_insuficiente");
    return;
  }

  // 3) carteira da loja
  ps = con.prepareStatement("SELECT id FROM carteiras WHERE tipo='LOJA' LIMIT 1");
  rs = dbQuery(con, ps);

  if(!rs.next()){
    con.rollback();
    response.sendRedirect("cliente.jsp?pagamento=sem_carteira_loja");
    return;
  }

  int carteiraLojaId = rs.getInt("id");
  dbClose(rs, ps, null);

  // 4) transferir saldo: cliente -> loja
  ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id=?");
  ps.setDouble(1, total);
  ps.setInt(2, carteiraClienteId);
  dbUpdate(con, ps);
  dbClose(null, ps, null);

  ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id=?");
  ps.setDouble(1, total);
  ps.setInt(2, carteiraLojaId);
  dbUpdate(con, ps);
  dbClose(null, ps, null);

  // 5) auditoria
  ps = con.prepareStatement(
    "INSERT INTO movimentos_carteira(tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao) " +
    "VALUES('PAGAMENTO_ENCOMENDA', ?, ?, ?, ?)"
  );
  ps.setDouble(1, total);
  ps.setInt(2, carteiraClienteId);
  ps.setInt(3, carteiraLojaId);
  ps.setString(4, "Pagamento da encomenda ID " + encomendaId);
  dbUpdate(con, ps);
  dbClose(null, ps, null);

  // 6) mudar estado da encomenda para PAGA
  ps = con.prepareStatement("UPDATE encomendas SET estado='PAGA' WHERE id=? AND cliente_id=?");
  ps.setLong(1, encomendaId);
  ps.setInt(2, userId);
  dbUpdate(con, ps);

  con.commit();
  response.sendRedirect("cliente.jsp?pagamento=ok");
  return;

} catch(Exception e){
  try{ if(con != null) con.rollback(); }catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rs, ps, con);
}
%>