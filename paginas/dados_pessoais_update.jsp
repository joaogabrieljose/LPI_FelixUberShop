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

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String telefone = request.getParameter("telefone");
String morada = request.getParameter("morada");

if (nome == null || nome.trim().isEmpty()) {
    response.sendRedirect("cliente.jsp?erro=1");
    return;
}

Connection con = null;
PreparedStatement ps = null;

try {
    con = dbConnect();
    ps = con.prepareStatement(
        "UPDATE utilizadores SET nome=?, email=?, telefone=?, morada=? WHERE id=? LIMIT 1"
    );
    ps.setString(1, nome.trim());
    ps.setString(2, (email != null ? email.trim() : ""));
    ps.setString(3, (telefone != null ? telefone.trim() : ""));
    ps.setString(4, (morada != null ? morada.trim() : ""));
    ps.setInt(5, userId);

    int linhas = dbUpdate(con, ps);

    if (linhas > 0) {
        response.sendRedirect("cliente.jsp?ok=1");
    } else {
        response.sendRedirect("cliente.jsp?erro=1");
    }

} catch (Exception e) {
    response.sendRedirect("cliente.jsp?erro=1");
} finally {
    dbClose(null, ps, con);
}
%>