<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String utilizador = request.getParameter("utilizador");
String senha = request.getParameter("senha");

if (utilizador == null || senha == null || utilizador.trim().isEmpty() || senha.trim().isEmpty()) {
    response.sendRedirect("index.jsp?login=erro_campos");
    return;
}

try {
    con = dbConnect();

    ps = con.prepareStatement(
      "SELECT id, perfil FROM utilizadores WHERE username=? AND password=? AND ativo=1 LIMIT 1"
    );
    ps.setString(1, utilizador.trim());
    ps.setString(2, senha);

    rs = dbQuery(con, ps);

    if (rs.next()) {
        session.setAttribute("userId", rs.getInt("id"));
        session.setAttribute("username", utilizador.trim());
        session.setAttribute("perfil", rs.getString("perfil"));

        String perfil = rs.getString("perfil");
        if ("ADMIN".equalsIgnoreCase(perfil)) {
            response.sendRedirect("admin.jsp");
        } else if ("FUNCIONARIO".equalsIgnoreCase(perfil)) {
            response.sendRedirect("funcionario.jsp");
        } else {
            response.sendRedirect("cliente.jsp");
        }
    } else {
        response.sendRedirect("index.jsp?login=erro");
    }

} catch (Exception e) {
    out.print("Erro: " + e.getMessage());
} 
%>