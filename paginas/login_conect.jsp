<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String BASE = request.getContextPath() + "/paginas/";

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String utilizador = request.getParameter("utilizador");
String senha = request.getParameter("senha");

if (utilizador == null || senha == null || utilizador.trim().isEmpty() || senha.trim().isEmpty()) {
    response.sendRedirect(BASE + "index.jsp?login=erro_campos");
    return;
}

try {
    con = dbConnect();

    ps = con.prepareStatement(
      "SELECT id, username, perfil, ativo " +
      "FROM utilizadores " +
      "WHERE username=? AND password=? LIMIT 1"
    );
    ps.setString(1, utilizador.trim());
    ps.setString(2, senha);

    rs = dbQuery(con, ps);

    if (rs.next()) {

        int id = rs.getInt("id");
        String userDB = rs.getString("username");  
        String perfDB = rs.getString("perfil");
        int ativo = rs.getInt("ativo");

        // se estiver pendente/inativo
        if (ativo != 1) {
            response.sendRedirect(BASE + "index.jsp?login=pendente");
            return;
        }

        //  limpar sessão antiga (boa prática)
        session.invalidate();
        session = request.getSession(true);

        //  sessão
        session.setAttribute("userId", id);
        session.setAttribute("username", userDB);
        session.setAttribute("perfil", perfDB);

        // opcional: 30 min
        session.setMaxInactiveInterval(30 * 60);

        // redireciona por perfil
        if ("ADMIN".equalsIgnoreCase(perfDB)) {
            response.sendRedirect(BASE + "admin.jsp");
        } else if ("FUNCIONARIO".equalsIgnoreCase(perfDB)) {
            response.sendRedirect(BASE + "funcionario.jsp");
        } else {
            response.sendRedirect(BASE + "cliente.jsp");
        }
        return;

    } else {
        response.sendRedirect(BASE + "index.jsp?login=erro");
        return;
    }

} catch (Exception e) {
    out.print("Erro: " + e.getMessage());
} finally {
    dbClose(rs, ps, con); 
}
%>