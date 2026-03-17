<%@ page contentType="text/html; charset=UTF-8" %>

<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title></title>
</head>
<body>

		
	<% 
	String nome = "nome recebido: " + request.getParameter("nome");

		out.print(nome); 

	%>

</body>
</html>