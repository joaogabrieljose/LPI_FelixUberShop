<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%-- Restrição de acesso: apenas ADMIN --%>
<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");
String username = (String) session.getAttribute("username");

if (perfil == null || userId == null || !perfil.equalsIgnoreCase("ADMIN")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

/* Cards dinâmicos */
int totalProdutos = 0;
int totalEncomendas = 0;
int totalUtilizadores = 0;

Connection conA = null;
PreparedStatement psA = null;
ResultSet rsA = null;

try {
  conA = dbConnect();

  psA = conA.prepareStatement("SELECT COUNT(*) AS t FROM produtos WHERE ativo=1");
  rsA = dbQuery(conA, psA);
  if (rsA.next()) totalProdutos = rsA.getInt("t");
  dbClose(rsA, psA, null);

  psA = conA.prepareStatement("SELECT COUNT(*) AS t FROM encomendas");
  rsA = dbQuery(conA, psA);
  if (rsA.next()) totalEncomendas = rsA.getInt("t");
  dbClose(rsA, psA, null);

  psA = conA.prepareStatement("SELECT COUNT(*) AS t FROM utilizadores WHERE ativo=1");
  rsA = dbQuery(conA, psA);
  if (rsA.next()) totalUtilizadores = rsA.getInt("t");

} catch(Exception e){
  out.print("Erro: " + e.getMessage());
} finally {
  dbClose(rsA, psA, conA);
}
%>

<%-- Lista de produtos (admin) --%>
<%
Connection conProd = null;
PreparedStatement psProd = null;
ResultSet rsProd = null;

try {
  conProd = dbConnect();
  psProd = conProd.prepareStatement(
    "SELECT id, nome, descricao, categoria, preco, ativo FROM produtos ORDER BY id DESC"
  );
  rsProd = dbQuery(conProd, psProd);
} catch(Exception e){
  out.print("Erro ao carregar produtos: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Admin - FelixUberShop</title>
  <link rel="stylesheet" href="admin.css">
</head>
<body>

<header class="dash-top">
  <div class="dash-brand">
    <a class="brand" href="index.jsp">
      <img src="legumes.png" class="logo" alt="FelixUberShop">
    </a>
    <div>
      <h1>FelixUberShop</h1>
      <p>Área de Administração</p>
    </div>
  </div>

  <div class="dash-user">
    <span class="pill">🛠️ <%= username %></span>
  </div>
</header>

<div class="dash-layout">

  <aside class="dash-side">
    <nav class="menu">
      <a class="active" href="admin.jsp">Dashboard</a>

      <!-- ID corrigido: o JS vai procurar por abrirProdutosAdmin -->
      <a href="#" id="abrirProdutosAdmin">Gerir Produtos</a>

      <a href="#">Gerir Promoções</a>
      <a href="#">Gerir Encomendas</a>
      <a href="#">Gerir Utilizadores</a>
      <a href="#">Carteira da Loja</a>
      <a href="logout.jsp">Logout</a>
    </nav>
  </aside>

  <main class="dash-main">

    <section class="dash-hero">
      <div class="dash-hero-text">
        <h2>Painel de Administração</h2>
        <p>Gestão global da FelixUberShop: produtos, promoções, utilizadores e encomendas.</p>
      </div>
    </section>

    <section class="dash-cards">
      <article class="dash-card">
        <h3>Produtos ativos</h3>
        <p class="dash-big"><%= totalProdutos %></p>
        <p class="dash-muted">Produtos disponíveis</p>
      </article>

      <article class="dash-card">
        <h3>Encomendas</h3>
        <p class="dash-big"><%= totalEncomendas %></p>
        <p class="dash-muted">Total no sistema</p>
      </article>

      <article class="dash-card">
        <h3>Utilizadores</h3>
        <p class="dash-big"><%= totalUtilizadores %></p>
        <p class="dash-muted">Contas ativas</p>
      </article>
    </section>

    <section class="dash-section">
      <div class="dash-section-top">
        <h3>Atalhos</h3>
      </div>
      <p>
        • Gerir Produtos: criar/editar/inativar<br>
        • Gerir Promoções: criar/ativar/desativar<br>
        • Gerir Encomendas: ver/validar/cancelar<br>
      </p>
    </section>

  </main>
</div>

<!-- MODAL: Gerir Produtos -->
<div id="produtosAdminModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gerir Produtos</h2>
      <a href="#" class="modal-close" id="fecharProdutosAdmin">✕</a>
    </div>

    <!-- TABS / ZONAS -->
    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-listar">Listar</button>
      <button type="button" class="tab-btn" data-tab="tab-adicionar">Adicionar</button>
      <button type="button" class="tab-btn" data-tab="tab-editar">Editar</button>
      <button type="button" class="tab-btn" data-tab="tab-estado">Ativar/Inativar</button>
    </div>

    <!-- 1) LISTAR -->
    <section id="tab-listar" class="tab-pane active">
      <h3>Produtos</h3>
      <div class="admin-table">
        <div class="row head">
          <div>ID</div><div>Nome</div><div>Categoria</div><div>Preço</div><div>Ativo</div>
        </div>

        <%
          boolean temProd = false;
          if (rsProd != null) {
            while (rsProd.next()) {
              temProd = true;
              int pid = rsProd.getInt("id");
              String pNome = rsProd.getString("nome");
              String pCat  = rsProd.getString("categoria");
              String pDesc = rsProd.getString("descricao");
              double pPreco = rsProd.getDouble("preco");
              int pAtivo = rsProd.getInt("ativo");
        %>
              <div class="row">
                <div><%= pid %></div>
                <div>
                  <strong><%= pNome %></strong><br>
                  <small class="muted"><%= (pDesc != null ? pDesc : "") %></small>
                </div>
                <div><%= (pCat != null ? pCat : "") %></div>
                <div><%= String.format("%.2f €", pPreco) %></div>
                <div><%= (pAtivo == 1 ? "Sim" : "Não") %></div>
              </div>
        <%
            }
          }
          if (!temProd) {
        %>
            <div class="row"><div style="grid-column:1/-1;">Sem produtos.</div></div>
        <%
          }
        %>
      </div>
    </section>

    <!-- 2) ADICIONAR -->
    <section id="tab-adicionar" class="tab-pane">
      <h3>Novo Produto</h3>
      <form action="admin_produto.jsp" method="POST" class="form-grid">
        <div>
          <label>Nome</label>
          <input type="text" name="nome" required>
        </div>
        <div>
          <label>Categoria</label>
          <input type="text" name="categoria">
        </div>
        <div style="grid-column:1/-1;">
          <label>Descrição</label>
          <input type="text" name="descricao">
        </div>
        <div>
          <label>Preço (€)</label>
          <input type="number" step="0.01" min="0.01" name="preco" required>
        </div>
        <div class="form-actions">
          <button type="submit" class="btn-submit">Adicionar</button>
        </div>
      </form>
    </section>

    <!-- 3) EDITAR (por ID) -->
    <section id="tab-editar" class="tab-pane">
      <h3>Editar Produto</h3>
      <p class="muted">Introduz o ID do produto e altera os campos.</p>

      <form action="admin_produto_update.jsp" method="POST" class="form-grid">
        <div>
          <label>ID</label>
          <input type="number" name="id" required>
        </div>
        <div>
          <label>Nome</label>
          <input type="text" name="nome" required>
        </div>
        <div>
          <label>Categoria</label>
          <input type="text" name="categoria">
        </div>
        <div>
          <label>Preço (€)</label>
          <input type="number" step="0.01" min="0.01" name="preco" required>
        </div>
        <div class="form-actions">
          <button type="submit" class="btn-submit">Guardar alterações</button>
        </div>
      </form>
    </section>

    <!-- 4) ATIVAR / INATIVAR (por ID) -->
    <section id="tab-estado" class="tab-pane">
      <h3>Ativar / Inativar Produto</h3>
      <p class="muted">Introduz o ID e escolhe a ação.</p>

      <div class="estado-actions">
        <form action="admin_produto_toggle_force.jsp" method="POST" class="inline-form">
          <input type="hidden" name="modo" value="ATIVAR">
          <input type="number" name="id" placeholder="ID do produto" required>
          <button type="submit" class="btn-mini pay">Ativar</button>
        </form>

        <form action="admin_produto_toggle_force.jsp" method="POST" class="inline-form">
          <input type="hidden" name="modo" value="INATIVAR">
          <input type="number" name="id" placeholder="ID do produto" required>
          <button type="submit" class="btn-mini danger">Inativar</button>
        </form>
      </div>
    </section>

  </div>
</div>

<%
dbClose(rsProd, psProd, conProd);
%>

<script id="admin-produtos-modal-js">
  const produtosAdminModal = document.getElementById("produtosAdminModal");
  const abrirProdutosAdmin = document.getElementById("abrirProdutosAdmin");
  const fecharProdutosAdmin = document.getElementById("fecharProdutosAdmin");

  if (abrirProdutosAdmin) {
    abrirProdutosAdmin.addEventListener("click", function(e){
      e.preventDefault();
      produtosAdminModal.classList.add("show");
    });
  }

  if (fecharProdutosAdmin) {
    fecharProdutosAdmin.addEventListener("click", function(e){
      e.preventDefault();
      produtosAdminModal.classList.remove("show");
    });
  }

  // clicar fora fecha
  if (produtosAdminModal) {
    produtosAdminModal.addEventListener("click", function(e){
      if (e.target.id === "produtosAdminModal") produtosAdminModal.classList.remove("show");
    });
  }

  // ESC fecha
  document.addEventListener("keydown", function(e){
    if (e.key === "Escape" && produtosAdminModal) produtosAdminModal.classList.remove("show");
  });

  // Tabs (se existirem)
  const tabBtns = document.querySelectorAll(".tab-btn");
  const panes = document.querySelectorAll(".tab-pane");

  tabBtns.forEach(btn=>{
    btn.addEventListener("click", ()=>{
      tabBtns.forEach(b=>b.classList.remove("active"));
      panes.forEach(p=>p.classList.remove("active"));
      btn.classList.add("active");
      document.getElementById(btn.dataset.tab).classList.add("active");
    });
  });
</script>

</body>
</html>