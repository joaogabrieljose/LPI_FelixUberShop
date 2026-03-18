<%@ page contentType="text/html; charset=UTF-8" %>

<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title></title>
</head>
<body>
	<main>
		<div class="container">
			<div class="row">
				<div class="col-12">
					<h1>Logout</h1>
				</div>
			</div>



		
	
	<% 
		String nome = "nome recebido: " + request.getParameter("nome");
		out.print(nome); 

	%>

	</main>


		
	
	<h1>Logout</h1>

</body>
</html>