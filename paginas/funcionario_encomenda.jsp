<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
/* restrição de acesso */
String perfil = (String) session.getAttribute("perfil");
Integer userIdObj = (Integer) session.getAttribute("userId");

if (perfil == null || userIdObj == null || !perfil.equalsIgnoreCase("FUNCIONARIO")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}
int funcId = userIdObj.intValue();

/* Para voltar ao mesmo sitio no front (modal Gerir Encomendas -> tab Criar) */
String BACK = "funcionario.jsp?modal=gerir&tab=criar";

/* ===================== INPUTS ===================== */
String clienteStr = request.getParameter("cliente_id");
String produtoStr = request.getParameter("produto_id");
String qtdStr     = request.getParameter("quantidade");

if (clienteStr == null || produtoStr == null || qtdStr == null || clienteStr.trim().isEmpty() || produtoStr.trim().isEmpty() || qtdStr.trim().isEmpty()) {
  response.sendRedirect(BACK + "&enc=erro_campos");
  return;
}

int clienteId, produtoId, qtd;
try {
  clienteId = Integer.parseInt(clienteStr.trim());
  produtoId = Integer.parseInt(produtoStr.trim());
  qtd = Integer.parseInt(qtdStr.trim());
} catch(Exception e){
  response.sendRedirect(BACK + "&enc=erro_id");
  return;
}

if (qtd <= 0) {
  response.sendRedirect(BACK + "&enc=erro_qtd");
  return;
}

/* ===================== DB ===================== */
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
  con = dbConnect();
  con.setAutoCommit(false); 

  //  confirmar cliente existe e esta ativo
  ps = con.prepareStatement("SELECT id FROM utilizadores WHERE id=? AND perfil='CLIENTE' AND ativo=1 LIMIT 1");
  ps.setInt(1, clienteId);
  rs = ps.executeQuery();
  if (!rs.next()) {
    dbClose(rs, ps, null);
    con.rollback();
    response.sendRedirect(BACK + "&enc=cliente_invalido");
    return;
  }
  dbClose(rs, ps, null);

  //  buscar produto e preco atual
  ps = con.prepareStatement("SELECT nome, preco FROM produtos WHERE id=? AND ativo=1 LIMIT 1");
  ps.setInt(1, produtoId);
  rs = ps.executeQuery();
  if (!rs.next()) {
    dbClose(rs, ps, null);
    con.rollback();
    response.sendRedirect(BACK + "&enc=produto_invalido");
    return;
  }
  String nomeProduto = rs.getString("nome");
  double precoUnit = rs.getDouble("preco");
  dbClose(rs, ps, null);

  double subtotal = precoUnit * qtd;
  if (subtotal <= 0) {
    con.rollback();
    response.sendRedirect(BACK + "&enc=total_invalido");
    return;
  }

  //  carteiras: cliente (UTILIZADOR) e loja (LOJA)
  int carteiraCliente = 0;
  double saldoCliente = 0.0;

  ps = con.prepareStatement("SELECT id, saldo FROM carteiras WHERE utilizador_id=? AND tipo='UTILIZADOR' LIMIT 1");
  ps.setInt(1, clienteId);
  rs = ps.executeQuery();
  if (rs.next()) {
    carteiraCliente = rs.getInt("id");
    saldoCliente = rs.getDouble("saldo");
  }
  dbClose(rs, ps, null);

  if (carteiraCliente == 0) {
    con.rollback();
    response.sendRedirect(BACK + "&enc=carteira_cliente_inexistente");
    return;
  }

  int carteiraLoja = 0;
  ps = con.prepareStatement("SELECT id FROM carteiras WHERE tipo='LOJA' LIMIT 1");
  rs = ps.executeQuery();
  if (rs.next()) carteiraLoja = rs.getInt("id");
  dbClose(rs, ps, null);

  if (carteiraLoja == 0) {
    con.rollback();
    response.sendRedirect(BACK + "&enc=carteira_loja_inexistente");
    return;
  }

  //  validar saldo suficiente
  if (saldoCliente < subtotal) {
    con.rollback();
    response.sendRedirect(BACK + "&enc=saldo_insuficiente");
    return;
  }

  //  gerar identificador unico (12 chars) e garantir na BD
  String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  String identificador = null;

  for (int tentativa = 0; tentativa < 20; tentativa++) {
    StringBuilder sb = new StringBuilder();
    for(int i=0;i<12;i++){
      int idx = (int)(Math.random() * chars.length());
      sb.append(chars.charAt(idx));
    }
    String cand = sb.toString();

    ps = con.prepareStatement("SELECT id FROM encomendas WHERE identificador=? LIMIT 1");
    ps.setString(1, cand);
    rs = ps.executeQuery();
    boolean existe = rs.next();
    dbClose(rs, ps, null);

    if (!existe) {
      identificador = cand;
      break;
    }
  }

  if (identificador == null) {
    con.rollback();
    response.sendRedirect(BACK + "&enc=erro_identificador");
    return;
  }

  //  criar encomenda como PAGA
  ps = con.prepareStatement(
    "INSERT INTO encomendas(identificador, cliente_id, estado, total) VALUES(?,?, 'PAGA', ?)",
    Statement.RETURN_GENERATED_KEYS
  );
  ps.setString(1, identificador);
  ps.setInt(2, clienteId);
  ps.setDouble(3, subtotal);
  ps.executeUpdate();

  rs = ps.getGeneratedKeys();
  long encomendaId = 0;
  if (rs.next()) encomendaId = rs.getLong(1);
  dbClose(rs, ps, null);

  if (encomendaId == 0) {
    con.rollback();
    response.sendRedirect(BACK + "&enc=erro_criar_encomenda");
    return;
  }

  //  inserir item
  ps = con.prepareStatement(
    "INSERT INTO encomenda_itens(encomenda_id, produto_id, quantidade, preco_unit, subtotal) VALUES(?,?,?,?,?)"
  );
  ps.setLong(1, encomendaId);
  ps.setInt(2, produtoId);
  ps.setInt(3, qtd);
  ps.setDouble(4, precoUnit);
  ps.setDouble(5, subtotal);
  ps.executeUpdate();
  dbClose(null, ps, null);

  //  atualizar saldos
  ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id=?");
  ps.setDouble(1, subtotal);
  ps.setInt(2, carteiraCliente);
  ps.executeUpdate();
  dbClose(null, ps, null);

  ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id=?");
  ps.setDouble(1, subtotal);
  ps.setInt(2, carteiraLoja);
  ps.executeUpdate();
  dbClose(null, ps, null);

  //  registar movimento (ENUM tem de bater certo) 
  String descricaoMov = "PAGAMENTO_ENCOMENDA identificador=" + identificador +
                        " funcionario_id=" + funcId +
                        " cliente_id=" + clienteId +
                        " produto_id=" + produtoId +
                        " produto_nome=" + (nomeProduto != null ? nomeProduto : "") +
                        " qtd=" + qtd; ps = con.prepareStatement(
    "INSERT INTO movimentos_carteira(tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao) " +
    "VALUES('PAGAMENTO_ENCOMENDA', ?, ?, ?, ?)"
  );
  ps.setDouble(1, subtotal);
  ps.setInt(2, carteiraCliente);
  ps.setInt(3, carteiraLoja);
  ps.setString(4, descricaoMov);
  ps.executeUpdate();
  dbClose(null, ps, null);

  con.commit();

  response.sendRedirect(BACK + "&enc=ok_criada_paga&id=" + encomendaId);
  return;

} catch(Exception e){
  try { if (con != null) con.rollback(); } catch(Exception ignored){}
  out.print("Erro: " + e.getMessage());
} finally {
  try { if (con != null) con.setAutoCommit(true); } catch(Exception ignored){}
  dbClose(rs, ps, con);
}
%>