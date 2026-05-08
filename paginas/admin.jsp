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

<%-- Lista de promoções (admin) --%>
<%
Connection conPr = null;
PreparedStatement psPr = null;
ResultSet rsPr = null;

try {
  conPr = dbConnect();
  psPr = conPr.prepareStatement(
    "SELECT id, titulo, descricao, desconto_percent, data_inicio, data_fim, ativa, criado_em " +
    "FROM promocoes ORDER BY id DESC"
  );
  rsPr = dbQuery(conPr, psPr);
} catch(Exception e){
  out.print("Erro ao carregar promoções: " + e.getMessage());
}
%>

<%
Connection conEnc = null;
PreparedStatement psEnc = null;
ResultSet rsEnc = null;

try {
  conEnc = dbConnect();
  psEnc = conEnc.prepareStatement(
    "SELECT e.id, e.identificador, e.estado, e.total, e.criado_em, u.username " +
    "FROM encomendas e JOIN utilizadores u ON u.id = e.cliente_id " +
    "ORDER BY e.criado_em DESC LIMIT 50"
  );
  rsEnc = dbQuery(conEnc, psEnc);
} catch(Exception e){
  out.print("Erro ao carregar encomendas (admin): " + e.getMessage());
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
      <a href="#" id="abrirProdutosAdmin">Gerir Produtos</a>
      <a href="#" id="abrirPromocoesAdmin">Gerir Promoções</a>
      <a href="#" id="abrirEncomendasAdmin">Gerir Encomendas</a>
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
  </main>
</div>

<!-- ===================== MODAL: PRODUTOS ===================== -->
<div id="produtosAdminModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gerir Produtos</h2>
      <a href="#" class="modal-close" id="fecharProdutosAdmin">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-listar-prod">Listar</button>
      <button type="button" class="tab-btn" data-tab="tab-adicionar-prod">Adicionar</button>
      <button type="button" class="tab-btn" data-tab="tab-editar-prod">Editar</button>
      <button type="button" class="tab-btn" data-tab="tab-estado-prod">Ativar/Inativar</button>
    </div>

    <section id="tab-listar-prod" class="tab-pane active">
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

    <section id="tab-adicionar-prod" class="tab-pane">
      <h3>Novo Produto</h3>
      <!-- ✅ action corrigido -->
      <form action="admin_produto_create.jsp" method="POST" class="form-grid">
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

    <section id="tab-editar-prod" class="tab-pane">
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

    <section id="tab-estado-prod" class="tab-pane">
      <h3>Ativar / Inativar Produto</h3>
      <p class="muted">Introduz o ID e escolhe a ação.</p>

      <div class="estado-actions">
        <!-- ✅ action corrigido -->
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

<!-- ===================== MODAL: PROMOÇÕES ===================== -->
<div id="promocoesAdminModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gerir Promoções</h2>
      <a href="#" class="modal-close" id="fecharPromocoesAdmin">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-prom-listar">Listar</button>
      <button type="button" class="tab-btn" data-tab="tab-prom-criar">Criar</button>
      <button type="button" class="tab-btn" data-tab="tab-prom-estado">Ativar/Desativar</button>
    </div>

    <section id="tab-prom-listar" class="tab-pane active">
      <h3>Promoções</h3>

      <div class="admin-table admin-promos">
        <div class="row head">
          <div>ID</div><div>Título</div><div>Desconto</div><div>Período</div><div>Ativa</div>
        </div>

        <%
          boolean temPr = false;
          if (rsPr != null) {
            while (rsPr.next()) {
              temPr = true;
              int pid = rsPr.getInt("id");
              String tit = rsPr.getString("titulo");
              String desc = rsPr.getString("descricao");
              int pct = rsPr.getInt("desconto_percent");   
              Date di = rsPr.getDate("data_inicio");
              Date df = rsPr.getDate("data_fim");
              int ativa = rsPr.getInt("ativa");
        %>
          <div class="row">
            <div><%= pid %></div>
            <div>
              <strong><%= tit %></strong><br>
              <small class="muted"><%= (desc != null ? desc : "") %></small>
            </div>
            <div><%= (rsPr.wasNull() ? "—" : (pct + "%")) %></div>
            <div><%= (di != null ? di.toString() : "—") %> → <%= (df != null ? df.toString() : "—") %></div>
            <div><%= (ativa == 1 ? "Sim" : "Não") %></div>
          </div>
        <%
            }
          }
          if (!temPr) {
        %>
          <div class="row"><div style="grid-column:1/-1;">Ainda não existem promoções.</div></div>
        <%
          }
        %>
      </div>
    </section>

    <section id="tab-prom-criar" class="tab-pane">
      <h3>Criar Promoção</h3>

      <!--  nomes certos para a tua tabela -->
      <form action="admin_promocoes_nova.jsp" method="POST" class="form-grid">
        <div style="grid-column:1/-1;">
          <label>Título</label>
          <input type="text" name="titulo" required>
        </div>

        <div style="grid-column:1/-1;">
          <label>Descrição</label>
          <textarea name="descricao" required style="width:100%; min-height:90px;"></textarea>
        </div>

        <div>
          <label>Desconto (%)</label>
          <input type="number" min="0" max="100" name="desconto_percent" placeholder="ex: 10">
        </div>

        <div>
          <label>Ativa?</label>
          <select name="ativa">
            <option value="1">Sim</option>
            <option value="0">Não</option>
          </select>
        </div>

        <div>
          <label>Data início</label>
          <input type="date" name="data_inicio">
        </div>

        <div>
          <label>Data fim</label>
          <input type="date" name="data_fim">
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-submit">Criar</button>
        </div>
      </form>
    </section>

    <section id="tab-prom-estado" class="tab-pane">
      <h3>Ativar / Desativar</h3>
      <p class="muted">Introduz o ID da promoção e escolhe a ação.</p>

      <div class="estado-actions">
        <form action="admin_promocoes_ativa.jsp" method="POST" class="inline-form">
          <input type="hidden" name="modo" value="ATIVAR">
          <input type="number" name="id" placeholder="ID da promoção" required>
          <button type="submit" class="btn-mini pay">Ativar</button>
        </form>

        <form action="admin_promocoes_ativa.jsp" method="POST" class="inline-form">
          <input type="hidden" name="modo" value="DESATIVAR">
          <input type="number" name="id" placeholder="ID da promoção" required>
          <button type="submit" class="btn-mini danger">Desativar</button>
        </form>
      </div>
    </section>

  </div>
</div>

<%
dbClose(rsPr, psPr, conPr);
%>

<!-- ===================== JS: abrir/fechar modais + tabs por modal ===================== -->
<script>
  // Abrir/Fechar Produtos
  const produtosAdminModal = document.getElementById("produtosAdminModal");
  const abrirProdutosAdmin = document.getElementById("abrirProdutosAdmin");
  const fecharProdutosAdmin = document.getElementById("fecharProdutosAdmin");

  if (abrirProdutosAdmin) abrirProdutosAdmin.addEventListener("click", (e)=>{ e.preventDefault(); produtosAdminModal.classList.add("show"); });
  if (fecharProdutosAdmin) fecharProdutosAdmin.addEventListener("click", (e)=>{ e.preventDefault(); produtosAdminModal.classList.remove("show"); });
  produtosAdminModal.addEventListener("click", (e)=>{ if(e.target.id==="produtosAdminModal") produtosAdminModal.classList.remove("show"); });

  // Abrir/Fechar Promoções
  const promocoesAdminModal = document.getElementById("promocoesAdminModal");
  const abrirPromocoesAdmin = document.getElementById("abrirPromocoesAdmin");
  const fecharPromocoesAdmin = document.getElementById("fecharPromocoesAdmin");

  if (abrirPromocoesAdmin) abrirPromocoesAdmin.addEventListener("click", (e)=>{ e.preventDefault(); promocoesAdminModal.classList.add("show"); });
  if (fecharPromocoesAdmin) fecharPromocoesAdmin.addEventListener("click", (e)=>{ e.preventDefault(); promocoesAdminModal.classList.remove("show"); });
  promocoesAdminModal.addEventListener("click", (e)=>{ if(e.target.id==="promocoesAdminModal") promocoesAdminModal.classList.remove("show"); });

  // ESC fecha ambos
  document.addEventListener("keydown", (e)=>{
    if(e.key==="Escape"){
      produtosAdminModal.classList.remove("show");
      promocoesAdminModal.classList.remove("show");
    }
  });

  // Tabs por modal (scoped)
  function initTabs(modalId){
    const modal = document.getElementById(modalId);
    if(!modal) return;
    const box = modal.querySelector(".modal-box");
    const btns = box.querySelectorAll(".tab-btn");
    const panes = box.querySelectorAll(".tab-pane");

    btns.forEach(btn=>{
      btn.addEventListener("click", ()=>{
        btns.forEach(b=>b.classList.remove("active"));
        panes.forEach(p=>p.classList.remove("active"));
        btn.classList.add("active");
        box.querySelector("#"+btn.dataset.tab).classList.add("active");
      });
    });
  }

  initTabs("produtosAdminModal");
  initTabs("promocoesAdminModal");
</script>


<!-- MODAL: Gerir Encomendas (ADMIN) -->
<div id="encomendasAdminModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Todas as encomendas</h2>
      <a href="#" class="modal-close" id="fecharEncomendasAdmin">✕</a>
    </div>

    <!-- LISTAR -->
    <section id="tab-enc-listar" class="tab-pane active">
      <h3>listagem </h3>

      <div class="admin-table admin-enc">
        <div class="row head">
          <div>Código</div><div>Cliente</div><div>Estado</div><div>Total</div><div>Data</div><div>Ações</div>
        </div>

        <%
          boolean temEnc = false;
          if (rsEnc != null) {
            while (rsEnc.next()) {
              temEnc = true;
              long eid = rsEnc.getLong("id");
              String cod = rsEnc.getString("identificador");
              String est = rsEnc.getString("estado");
              double tot = rsEnc.getDouble("total");
              Timestamp dt = rsEnc.getTimestamp("criado_em");
              String userCli = rsEnc.getString("username");
        %>
          <div class="row">
            <div><strong><%= cod %></strong></div>
            <div><%= userCli %></div>
            <div><%= est %></div>
            <div><%= String.format("%.2f €", tot) %></div>
            <div><%= (dt != null ? dt.toString().substring(0,16) : "") %></div>
            <div class="acoes">
              <form action="admin_encomenda_detalhes.jsp" method="GET" class="inline-form">
                <input type="hidden" name="id" value="<%= eid %>">
                <button type="submit" class="btn-mini">Ver</button>
              </form>

              <%-- Botões de estado (simples) --%>
              <% if ("PAGA".equalsIgnoreCase(est)) { %>
                <form action="admin_encomenda_estado.jsp" method="POST" class="inline-form">
                  <input type="hidden" name="id" value="<%= eid %>">
                  <input type="hidden" name="acao" value="VALIDAR">
                  <button type="submit" class="btn-mini pay">Validar</button>
                </form>
              <% } %>

              <% if ("VALIDADA".equalsIgnoreCase(est)) { %>
                <form action="admin_encomenda_estado.jsp" method="POST" class="inline-form">
                  <input type="hidden" name="id" value="<%= eid %>">
                  <input type="hidden" name="acao" value="ENTREGAR">
                  <button type="submit" class="btn-mini pay">Entregar</button>
                </form>
              <% } %>

              <% if (!"CANCELADA".equalsIgnoreCase(est) && !"ENTREGUE".equalsIgnoreCase(est)) { %>
                <form action="admin_encomenda_estado.jsp" method="POST" class="inline-form">
                  <input type="hidden" name="id" value="<%= eid %>">
                  <input type="hidden" name="acao" value="CANCELAR">
                  <button type="submit" class="btn-mini danger">Cancelar</button>
                </form>
              <% } %>
            </div>
          </div>
        <%
            }
          }
          if (!temEnc) {
        %>
          <div class="row"><div style="grid-column:1/-1;">Não existem encomendas.</div></div>
        <%
          }
        %>
      </div>
    </section>

  </div>
</div>

<script>
  // abrir/fechar encomendas
  const encomendasAdminModal = document.getElementById("encomendasAdminModal");
  const abrirEncomendasAdmin = document.getElementById("abrirEncomendasAdmin");
  const fecharEncomendasAdmin = document.getElementById("fecharEncomendasAdmin");

  if (abrirEncomendasAdmin) abrirEncomendasAdmin.addEventListener("click", (e)=>{ e.preventDefault(); encomendasAdminModal.classList.add("show"); });
  if (fecharEncomendasAdmin) fecharEncomendasAdmin.addEventListener("click", (e)=>{ e.preventDefault(); encomendasAdminModal.classList.remove("show"); });
  encomendasAdminModal.addEventListener("click", (e)=>{ if(e.target.id==="encomendasAdminModal") encomendasAdminModal.classList.remove("show"); });

  initTabs("encomendasAdminModal");
</script>


</body>
</html>