<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!-- Controlo de acesso por sessão/perfil: apenas CLIENTE -->
<%
String perfil = (String) session.getAttribute("perfil");
if (perfil == null || !perfil.equalsIgnoreCase("CLIENTE")) {
    response.sendRedirect("index.jsp?acesso=negado");
    return;
}
%>


<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Área do Cliente</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Área do Cliente</h1>
  <p>Bem-vindo, <%= session.getAttribute("username") %>!</p>

  <a href="logout.jsp">Logout</a>
</body>
</html>