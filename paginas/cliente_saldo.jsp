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

String acao = request.getParameter("acao");     // ADICIONAR ou LEVANTAR
String valorStr = request.getParameter("valor");

double valor = 0;
try { valor = Double.parseDouble(valorStr); } catch(Exception ex) { valor = 0; }

if (acao == null || valor <= 0) {
    response.sendRedirect("cliente.jsp?saldo=erro");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

    // 1) obter carteira do utilizador

    ps = con.prepareStatement("SELECT id, saldo FROM carteiras WHERE utilizador_id=? AND tipo='UTILIZADOR' LIMIT 1");
    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (!rs.next()) {
        con.rollback();
        response.sendRedirect("cliente.jsp?saldo=erro");
        return;
    }

    int carteiraId = rs.getInt("id");
    double saldoAtual = rs.getDouble("saldo");

    dbClose(rs, ps, null); // fecha rs e ps, mantém con

    if ("LEVANTAR".equalsIgnoreCase(acao) && saldoAtual < valor) {
        con.rollback();
        response.sendRedirect("cliente.jsp?saldo=insuficiente");
        return;
    }

    // 2) atualizar saldo

    if ("ADICIONAR".equalsIgnoreCase(acao)) {
        ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo + ? WHERE id=?");
        ps.setDouble(1, valor);
        ps.setInt(2, carteiraId);
        dbUpdate(con, ps);
        dbClose(null, ps, null);

        // 3) auditoria
        ps = con.prepareStatement(
          "INSERT INTO movimentos_carteira(tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao) " +
          "VALUES ('ADICIONAR', ?, NULL, ?, 'Adicionar saldo pelo cliente')"
        );
        ps.setDouble(1, valor);
        ps.setInt(2, carteiraId);
        dbUpdate(con, ps);

    } else { 
        
        // LEVANTAR
        ps = con.prepareStatement("UPDATE carteiras SET saldo = saldo - ? WHERE id=?");
        ps.setDouble(1, valor);
        ps.setInt(2, carteiraId);
        dbUpdate(con, ps);
        dbClose(null, ps, null);

        ps = con.prepareStatement(
          "INSERT INTO movimentos_carteira(tipo_operacao, valor, carteira_origem_id, carteira_destino_id, descricao) " +
          "VALUES ('LEVANTAR', ?, ?, NULL, 'Levantar saldo pelo cliente')"
        );
        ps.setDouble(1, valor);
        ps.setInt(2, carteiraId);
        dbUpdate(con, ps);
    }

    con.commit();
    response.sendRedirect("cliente.jsp?saldo=ok");

} catch (Exception e) {
    try { if (con != null) con.rollback(); } catch(Exception ignored) {}
    out.print("Erro: " + e.getMessage());
} finally {
    dbClose(null, ps, con);
}
%>