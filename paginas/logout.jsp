<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
  // Evitar cache de páginas autenticadas
  
  response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
  response.setHeader("Pragma", "no-cache"); // HTTP 1.0
  response.setDateHeader("Expires", 0); // Proxies

  // Terminar sessão
  if (session != null) {
    session.invalidate();
  }

  // Redirecionar corretamente (mesmo dentro de /paginas/)
  String BASE = request.getContextPath() + "/paginas/";
  response.sendRedirect(BASE + "index.jsp?logout=ok");
%>