<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userIdObj = (Integer) session.getAttribute("userId");

// Área de gestão: FUNCIONARIO e ADMIN
if (perfil == null || userIdObj == null ||
   !(perfil.equalsIgnoreCase("FUNCIONARIO") || perfil.equalsIgnoreCase("ADMIN"))) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}
int staffId = userIdObj.intValue();

String acao = request.getParameter("acao"); // ADICIONAR | LEVANTAR
String clienteStr = request.getParameter("cliente_id");
String valorStr = request.getParameter("valor");

if (acao == null || clienteStr == null || valorStr == null ||
    acao.trim().isEmpty() || clienteStr.trim().isEmpty() || valorStr.trim().isEmpty()) {
  response.sendRedirect("funcionario.jsp?msg=erro_campos&modal=carteiras");
  return;
}

int clienteId;
double valor;

try {
  clienteId = Integer.parseInt(clienteStr.trim());
  valor = Double.parseDouble(valorStr.trim());
} catch(Exception e){
  response.sendRedirect("funcionario.jsp?msg=erro_id&modal=carteiras");
  return;
}

acao = acao.trim().toUpperCase();
if (!(acao.equals("ADICIONAR") || acao.equals("LEVANTAR"))) {
  response.sendRedirect("funcionario.jsp?msg=acao_invalida&modal=carteiras");
  return;
}
if (valor <= 0) {
  response.sendRedirect("funcionario.jsp?msg=valor_invalido&modal=carteiras");
  return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false);

  // 1) validar cliente ativo
  ps = con.prepareStatement("SELECT id FROM utilizadores WHERE id=? AND perfil='CLIENTE' AND ativo=1 LIMIT 1");
  ps.setInt(1, clienteId);
  rs = ps.executeQuery();
  if (!rs.next()) {
    con.rollback();
    response.sendRedirect("funcionario.jsp?msg=cliente_invalido&modal=carteiras");
    return;
  }
  rs.close(); ps.close();

  // 2) carteira do cliente
  int carteiraCliente = 0;
  double saldoCliente = 0.0;

  ps = con.prepareStatement("SELECT id, saldo FROM carteiras WHERE utilizador_id=? AND tipo='UTILIZADOR' LIMIT 1");
  ps.setInt(1, clienteId);
  rs = ps.executeQuery();
  if (rs.next()) {
    carteiraCliente = rs.getInt("id");
    saldoCliente = rs.getDouble("saldo");
  }
  rs.close(); ps.close();

  if (carteiraCliente == 0) {
    con.rollback();
    response.sendRedirect("funcionario.jsp?msg=carteira_cliente_inexistente&modal=carteiras");
    return;
  }

  // 3) aplicar operação
  if (acao.equals("LEVANTAR") && saldoCliente < valor) {
    con.rollback();
    response.sendRedirect("funcionario.jsp?msg=saldo_insuficiente&modal=carteiras");
    return;
  }

  if (acao.equals("ADICIONAR")) {
    ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id=?");
  } else {
    ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id=?");
  }
  ps.setDouble(1, valor);
  ps.setInt(2, carteiraCliente);
  ps.executeUpdate();
  ps.close();

  // 4) registar movimento (enum: ADICIONAR / LEVANTAR)
  ps = con.prepareStatement(
    "INSERT INTO movimentos_carteira(tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao) " +
    "VALUES(?, ?, ?, ?, ?)"
  );

  String desc = (acao.equals("ADICIONAR") ? "Depósito" : "Levantamento")
              + " na carteira do cliente ID " + clienteId
              + " (feito por " + perfil.toUpperCase() + " ID " + staffId + ")";

  ps.setString(1, acao); // ADICIONAR ou LEVANTAR (TEM de existir no ENUM)
  ps.setDouble(2, valor);

  // Origem/Destino: como é ajuste interno, podes deixar NULL num dos lados:
  if (acao.equals("ADICIONAR")) {
    ps.setNull(3, Types.INTEGER);        // origem desconhecida
    ps.setInt(4, carteiraCliente);       // destino = cliente
  } else {
    ps.setInt(3, carteiraCliente);       // origem = cliente
    ps.setNull(4, Types.INTEGER);        // destino desconhecido
  }
  ps.setString(5, desc);

  ps.executeUpdate();
  ps.close();

  con.commit();
  response.sendRedirect("funcionario.jsp?msg=ok_carteira&modal=carteiras");
  return;

} catch(Exception e){
  try { if(con != null) con.rollback(); } catch(Exception ig){}
  out.print("Erro: " + e.getMessage());
} finally {
  try { if(con != null) con.setAutoCommit(true); } catch(Exception ig){}
  dbClose(rs, ps, con);
}
%>