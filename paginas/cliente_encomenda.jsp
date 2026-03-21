<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
/* ====== 1) Acesso: apenas CLIENTE autenticado ====== */
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");

if (perfil == null || userId == null || !perfil.equalsIgnoreCase("CLIENTE")) {
    response.sendRedirect("index.jsp?acesso=negado");
    return;
}

/* ====== 2) Validar parâmetros do form ====== */
String encStr  = request.getParameter("encomenda_id");
String prodStr = request.getParameter("produto_id");
String qtdStr  = request.getParameter("quantidade");

if (encStr == null || prodStr == null || qtdStr == null ||
    encStr.trim().isEmpty() || prodStr.trim().isEmpty() || qtdStr.trim().isEmpty()) {
    response.sendRedirect("cliente.jsp?enc=parametros_em_falta");
    return;
}

long encomendaId;
int produtoId;
int qtd;

try {
    encomendaId = Long.parseLong(encStr);
    produtoId   = Integer.parseInt(prodStr);
    qtd         = Integer.parseInt(qtdStr);
} catch (Exception ex) {
    response.sendRedirect("cliente.jsp?enc=parametros_invalidos");
    return;
}

if (qtd <= 0) {
    response.sendRedirect("cliente.jsp?enc=quantidade_invalida");
    return;
}

/* ====== 3) Operação BD: inserir item e atualizar total ====== */
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

    /* 3.1) Confirmar encomenda pertence ao cliente e está em RASCUNHO */
    ps = con.prepareStatement(
        "SELECT estado FROM encomendas WHERE id=? AND cliente_id=? LIMIT 1"
    );
    ps.setLong(1, encomendaId);
    ps.setInt(2, userId);
    rs = dbQuery(con, ps);

    if (!rs.next()) {
        con.rollback();
        response.sendRedirect("cliente.jsp?enc=inexistente");
        return;
    }

    String estado = rs.getString("estado");
    dbClose(rs, ps, null); // fecha rs+ps, mantém con

    if (!"RASCUNHO".equalsIgnoreCase(estado)) {
        con.rollback();
        response.sendRedirect("cliente.jsp?enc=nao_editavel");
        return;
    }

    /* 3.2) Buscar preço do produto (e confirmar que está ativo) */
    ps = con.prepareStatement(
        "SELECT preco FROM produtos WHERE id=? AND ativo=1 LIMIT 1"
    );
    ps.setInt(1, produtoId);
    rs = dbQuery(con, ps);

    if (!rs.next()) {
        con.rollback();
        response.sendRedirect("cliente.jsp?enc=produto_invalido");
        return;
    }

    double preco = rs.getDouble("preco");
    double subtotal = preco * qtd;

    dbClose(rs, ps, null);

    /* 3.3) Inserir item */
    ps = con.prepareStatement(
        "INSERT INTO encomenda_itens(encomenda_id, produto_id, quantidade, preco_unit, subtotal) " +
        "VALUES(?,?,?,?,?)"
    );
    ps.setLong(1, encomendaId);
    ps.setInt(2, produtoId);
    ps.setInt(3, qtd);
    ps.setDouble(4, preco);
    ps.setDouble(5, subtotal);
    dbUpdate(con, ps);

    dbClose(null, ps, null);

    /* 3.4) Recalcular e atualizar total da encomenda */
    ps = con.prepareStatement(
        "UPDATE encomendas " +
        "SET total = (SELECT IFNULL(SUM(subtotal),0) FROM encomenda_itens WHERE encomenda_id=?) " +
        "WHERE id=?"
    );
    ps.setLong(1, encomendaId);
    ps.setLong(2, encomendaId);
    dbUpdate(con, ps);

    con.commit();

    // Volta para a página de detalhes/edição (se tiveres) ou para cliente.jsp
    response.sendRedirect("encomenda_detalhes.jsp?id=" + encomendaId + "&ok=1");
    return;

} catch (Exception e) {
    try { if (con != null) con.rollback(); } catch(Exception ignored) {}
    out.print("Erro: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}
%>