<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
/* ===================== AUTH ===================== */
/* Área de gestão: acessível a FUNCIONARIO e ADMIN */
String perfil = (String) session.getAttribute("perfil");
Integer userIdObj = (Integer) session.getAttribute("userId");
String username = (String) session.getAttribute("username");

if (perfil == null || userIdObj == null ||
   !(perfil.equalsIgnoreCase("FUNCIONARIO") || perfil.equalsIgnoreCase("ADMIN"))) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}
int staffId = userIdObj.intValue(); // id do funcionário/admin logado

// msg de feedback
String msg = request.getParameter("msg"); // ok_... | erro_...

/* ===================== DADOS PESSOAIS (do logado) ===================== */
Connection conMe = null;
PreparedStatement psMe = null;
ResultSet rsMe = null;

String nome = "";
String email = "";
String telefone = "";
String morada = "";

try{
  conMe = dbConnect();
  psMe = conMe.prepareStatement(
    "SELECT nome, email, telefone, morada FROM utilizadores WHERE id=? LIMIT 1"
  );
  psMe.setInt(1, staffId);
  rsMe = dbQuery(conMe, psMe);

  if(rsMe.next()){
    nome = (rsMe.getString("nome") != null ? rsMe.getString("nome") : "");
    email = (rsMe.getString("email") != null ? rsMe.getString("email") : "");
    telefone = (rsMe.getString("telefone") != null ? rsMe.getString("telefone") : "");
    morada = (rsMe.getString("morada") != null ? rsMe.getString("morada") : "");
  }
} catch(Exception e){
  // não quebra
} finally {
  dbClose(rsMe, psMe, conMe);
}

/* ===================== CARD: validações do funcionário ===================== */
int totalValidadas = 0;
Connection conCnt = null;
PreparedStatement psCnt = null;
ResultSet rsCnt = null;

try{
  conCnt = dbConnect();
  psCnt = conCnt.prepareStatement("SELECT COUNT(*) AS t FROM encomendas WHERE validada_por=?");
  psCnt.setInt(1, staffId);
  rsCnt = dbQuery(conCnt, psCnt);
  if(rsCnt.next()) totalValidadas = rsCnt.getInt("t");
} catch(Exception e){
  // ignora
} finally {
  dbClose(rsCnt, psCnt, conCnt);
}

/* ===================== SELECT: TODAS as encomendas (para validar) ===================== */
Connection conSel = null;
PreparedStatement psSel = null;
ResultSet rsSel = null;

try{
  conSel = dbConnect();
  psSel = conSel.prepareStatement(
    "SELECT e.id, e.identificador, e.estado, e.total, e.criado_em, u.username " +
    "FROM encomendas e " +
    "JOIN utilizadores u ON u.id = e.cliente_id " +
    "ORDER BY e.criado_em DESC LIMIT 200"
  );
  rsSel = dbQuery(conSel, psSel);
} catch(Exception e){
  out.print("Erro ao carregar encomendas: " + e.getMessage());
}

/* ===================== SELECT: CLIENTES (para criar encomenda + gerir carteira) ===================== */
Connection conCli = null;
PreparedStatement psCli = null;
ResultSet rsCli = null;

try{
  conCli = dbConnect();
  psCli = conCli.prepareStatement(
    "SELECT u.id, u.username, u.nome, u.email, c.id AS carteira_id, c.saldo " +
    "FROM utilizadores u " +
    "LEFT JOIN carteiras c ON c.utilizador_id=u.id AND c.tipo='UTILIZADOR' " +
    "WHERE u.perfil='CLIENTE' AND u.ativo=1 " +
    "ORDER BY u.username ASC"
  );
  rsCli = dbQuery(conCli, psCli);
} catch(Exception e){
  out.print("Erro ao carregar clientes: " + e.getMessage());
}

/* ===================== SELECT: PRODUTOS (para criar encomenda) ===================== */
Connection conProd = null;
PreparedStatement psProd = null;
ResultSet rsProd = null;

try{
  conProd = dbConnect();
  psProd = conProd.prepareStatement(
    "SELECT id, nome, categoria, preco " +
    "FROM produtos WHERE ativo=1 " +
    "ORDER BY categoria, nome"
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
  <title>Área de Gestão - FelixUberShop</title>
  <link rel="stylesheet" href="cliente_dados_pessoais.css">
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
      <p>Área de Gestão</p>
    </div>
  </div>

  <div class="dash-user">
    <span class="pill"><%= (username != null ? username : "") %> (<%= perfil %>)</span>
  </div>
</header>

<div class="dash-layout">

  <aside class="dash-side">
    <nav class="menu">
      <a class="active" href="funcionario.jsp">Dashboard</a>
      <a href="#" id="abrirDadosLink">Dados pessoais</a>
      <a href="#" id="abrirGerirEnc">Gestão de encomendas</a>
      <a href="#" id="abrirCarteirasLink">Gestão de carteira (clientes)</a>
      <a href="logout.jsp">Logout</a>
    </nav>
  </aside>

  <main class="dash-main">

    <section class="dash-hero">
      <div class="dash-hero-text">
        <h2>Painel de Gestão</h2>
        <p>Encomendas + carteiras de clientes + dados pessoais.</p>

        <% if (msg != null) { %>
          <p style="font-weight:900; color:<%= (msg.startsWith("ok") ? "green" : "red") %>;">
            <%= (msg.startsWith("ok") ? "Operação realizada com sucesso." : ("Erro: " + msg)) %>
          </p>
        <% } %>

        <div class="dash-actions">
          <a class="btn" href="#" id="abrirGerirEnc2">Gerir encomendas</a>
          <a class="btn outline" href="#" id="abrirCarteirasLink2">Gerir carteiras</a>
          <a class="btn outline" href="#" id="abrirDadosLink2">Editar dados</a>
        </div>
      </div>
    </section>

    <section class="dash-cards">
      <article class="dash-card">
        <h3>Validações realizadas</h3>
        <p class="dash-big"><%= totalValidadas %></p>
        <p class="dash-muted">Encomendas validadas por ti</p>
      </article>
    </section>

  </main>
</div>

<!-- ================= MODAL: GESTÃO DE ENCOMENDAS (VALIDAR + CRIAR) ================= -->
<div id="gerirEncModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gestão de Encomendas</h2>
      <a href="#" class="modal-close" id="fecharGerirEnc">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-gerir-validar">Validar</button>
      <button type="button" class="tab-btn" data-tab="tab-gerir-criar">Criar encomenda</button>
    </div>

    <!-- VALIDAR -->
    <section id="tab-gerir-validar" class="tab-pane active">
      <p class="muted">Seleciona uma encomenda. Só valida se ela estiver <strong>PAGA</strong>.</p>

      <form action="funcionario_validar.jsp" method="POST" class="form-grid">
        <div style="grid-column:1/-1;">
          <label>Encomenda</label>
          <select name="id" required>
            <option value="">-- Selecionar encomenda --</option>
            <%
              while (rsSel != null && rsSel.next()) {
            %>
              <option value="<%= rsSel.getLong("id") %>">
                <%= rsSel.getString("identificador") %> | <%= rsSel.getString("username") %> | <%= rsSel.getString("estado") %> | <%= String.format("%.2f €", rsSel.getDouble("total")) %>
              </option>
            <%
              }
            %>
          </select>
        </div>

        <div class="form-actions" style="grid-column:1/-1;">
          <button type="submit" class="btn-submit">Validar</button>
        </div>
      </form>
    </section>

    <!-- CRIAR (cobra carteira do cliente) -->
    <section id="tab-gerir-criar" class="tab-pane">
      <p class="muted">Seleciona o cliente e o produto (com preço). Depois indica a quantidade.</p>

      <form action="funcionario_encomenda.jsp" method="POST" class="form-grid">

        <div style="grid-column:1/-1;">
          <label>Cliente</label>
          <select name="cliente_id" required>
            <option value="">-- Selecionar cliente --</option>
            <%
              // ATENÇÃO: rsCli também vai ser usado no modal de carteiras.
              // Por isso NÃO reutilizamos rsCli aqui (para não "gastar" o cursor).
              // Vamos reconstruir a lista no modal de carteiras com uma query separada lá.
              //
              // Aqui, para simplificar, vamos só mostrar uma mensagem e pedir para escolher no modal de carteiras.
            %>
            <option value="" disabled>Seleciona o cliente no modal “Gestão de carteira” (lista completa).</option>
          </select>
          <p class="muted" style="margin-top:8px;">
            Nota: Para evitar bugs de ResultSet (cursor), a lista completa de clientes está no modal “Gestão de carteira”.
          </p>
        </div>

        <div style="grid-column:1/-1;">
          <label>Produto</label>
          <select name="produto_id" required>
            <option value="">-- Selecionar produto --</option>
            <%
              boolean temProdutos = false;
              while (rsProd != null && rsProd.next()) {
                temProdutos = true;
                int pid = rsProd.getInt("id");
                String pnome = rsProd.getString("nome");
                String pcat  = rsProd.getString("categoria");
                double ppreco = rsProd.getDouble("preco");
            %>
              <option value="<%= pid %>">
                ID <%= pid %> | <%= (pcat != null ? (pcat + " — ") : "") %><%= pnome %> — <%= String.format("%.2f €", ppreco) %>
              </option>
            <%
              }
              if (!temProdutos) {
            %>
              <option value="" disabled>Sem produtos ativos</option>
            <%
              }
            %>
          </select>
        </div>

        <div>
          <label>Quantidade</label>
          <input type="number" name="quantidade" min="1" value="1" required>
        </div>

        <div class="form-actions" style="grid-column:1/-1;">
          <button type="submit" class="btn-submit">Criar e Cobrar</button>
        </div>

      </form>
    </section>

  </div>
</div>

<!-- ================= MODAL: GESTÃO DE CARTEIRA (CLIENTES) ================= -->
<div id="carteirasModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gestão de Saldo (Clientes)</h2>
      <a href="#" class="modal-close" id="fecharCarteirasLink">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-car-lista">Clientes</button>
      <button type="button" class="tab-btn" data-tab="tab-car-operar">Operar saldo</button>
    </div>

    <!-- LISTA clientes/saldos -->
    <section id="tab-car-lista" class="tab-pane active">
      <div class="admin-table">
        <div class="row head">
          <div>ID</div><div>Username</div><div>Nome</div><div>Carteira</div><div>Saldo</div>
        </div>

        <%
          boolean temC = false;
          if (rsCli != null) {
            while (rsCli.next()) {
              temC = true;
              int cid = rsCli.getInt("id");
              String ucli = rsCli.getString("username");
              String ncli = rsCli.getString("nome");
              int carId = rsCli.getInt("carteira_id");
              double saldo = rsCli.getDouble("saldo");
        %>
          <div class="row" style="grid-template-columns:0.5fr 1fr 1.2fr 0.8fr 0.6fr;">
            <div><%= cid %></div>
            <div><strong><%= (ucli != null ? ucli : "") %></strong></div>
            <div><%= (ncli != null ? ncli : "") %></div>
            <div><%= (carId > 0 ? carId : 0) %></div>
            <div><%= String.format("%.2f €", saldo) %></div>
          </div>
        <%
            }
          }
          if (!temC) {
        %>
          <div class="row"><div style="grid-column:1/-1;">Sem clientes ativos.</div></div>
        <%
          }
        %>
      </div>
    </section>

    <!-- OPERAR (depositar/levantar) -->
    <section id="tab-car-operar" class="tab-pane">
      <p class="muted">Escolhe um cliente pelo ID e indica o valor. O sistema regista em movimentos_carteira.</p>

      <div class="estado-actions" style="gap:14px; flex-wrap:wrap;">
        <!-- DEPOSITAR -->
        <form action="funcionario_carteira_cliente.jsp" method="POST" class="inline-form">
          <input type="hidden" name="acao" value="ADICIONAR">
          <input type="number" name="cliente_id" placeholder="ID do cliente" required>
          <input type="number" name="valor" step="0.01" min="0.01" placeholder="Valor (€)" required>
          <button type="submit" class="btn-mini pay">Depositar</button>
        </form>

        <!-- LEVANTAR -->
        <form action="funcionario_carteira_cliente.jsp" method="POST" class="inline-form">
          <input type="hidden" name="acao" value="LEVANTAR">
          <input type="number" name="cliente_id" placeholder="ID do cliente" required>
          <input type="number" name="valor" step="0.01" min="0.01" placeholder="Valor (€)" required>
          <button type="submit" class="btn-mini danger">Levantar</button>
        </form>
      </div>

      <p class="muted" style="margin-top:10px;">
        Dica: usa a tab “Clientes” para veres o ID e o saldo antes de operar.
      </p>
    </section>

  </div>
</div>

<!-- ================= MODAL: DADOS PESSOAIS ================= -->
<div id="dadosModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>Dados Pessoais</h2>
      <a href="#" class="modal-close" id="fecharDadosLink">✕</a>
    </div>

    <!-- Reutiliza o mesmo backend -->
    <form action="dados_pessoais_update.jsp" method="POST" class="login-form">
      <input type="hidden" name="redir" value="funcionario.jsp">

      <label for="nome">Nome</label>
      <input type="text" id="nome" name="nome" value="<%= nome %>" required>

      <label for="email">Email</label>
      <input type="email" id="email" name="email" value="<%= email %>">

      <label for="telefone">Telefone</label>
      <input type="text" id="telefone" name="telefone" value="<%= telefone %>">

      <label for="morada">Morada</label>
      <input type="text" id="morada" name="morada" value="<%= morada %>">

      <button type="submit" class="btn-submit">Guardar</button>
    </form>
  </div>
</div>

<script>
  // ========= helpers tabs (scoped) =========
  function initTabsInside(modalEl){
    if(!modalEl) return;
    const box = modalEl.querySelector(".modal-box");
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

  // ========= MODAL: encomendas =========
  const gerirEncModal = document.getElementById("gerirEncModal");
  function openGerir(e){ if(e) e.preventDefault(); gerirEncModal.classList.add("show"); }
  document.getElementById("abrirGerirEnc")?.addEventListener("click", openGerir);
  document.getElementById("abrirGerirEnc2")?.addEventListener("click", openGerir);
  document.getElementById("fecharGerirEnc")?.addEventListener("click",(e)=>{e.preventDefault(); gerirEncModal.classList.remove("show");});
  gerirEncModal?.addEventListener("click",(e)=>{ if(e.target.id==="gerirEncModal") gerirEncModal.classList.remove("show"); });
  initTabsInside(gerirEncModal);

  // ========= MODAL: carteiras =========
  const carteirasModal = document.getElementById("carteirasModal");
  function openCarteiras(e){ if(e) e.preventDefault(); carteirasModal.classList.add("show"); }
  document.getElementById("abrirCarteirasLink")?.addEventListener("click", openCarteiras);
  document.getElementById("abrirCarteirasLink2")?.addEventListener("click", openCarteiras);
  document.getElementById("fecharCarteirasLink")?.addEventListener("click",(e)=>{e.preventDefault(); carteirasModal.classList.remove("show");});
  carteirasModal?.addEventListener("click",(e)=>{ if(e.target.id==="carteirasModal") carteirasModal.classList.remove("show"); });
  initTabsInside(carteirasModal);

  // ========= MODAL: dados pessoais =========
  const dadosModal = document.getElementById("dadosModal");
  function openDados(e){ if(e) e.preventDefault(); dadosModal.classList.add("show"); }
  document.getElementById("abrirDadosLink")?.addEventListener("click", openDados);
  document.getElementById("abrirDadosLink2")?.addEventListener("click", openDados);
  document.getElementById("fecharDadosLink")?.addEventListener("click",(e)=>{e.preventDefault(); dadosModal.classList.remove("show");});
  dadosModal?.addEventListener("click",(e)=>{ if(e.target.id==="dadosModal") dadosModal.classList.remove("show"); });

  // ESC fecha tudo
  document.addEventListener("keydown",(e)=>{
    if(e.key==="Escape"){
      gerirEncModal?.classList.remove("show");
      carteirasModal?.classList.remove("show");
      dadosModal?.classList.remove("show");
    }
  });

  // auto abrir (opcional): ?modal=carteiras
  const params = new URLSearchParams(window.location.search);
  if (params.get("modal")==="carteiras") openCarteiras();
  if (params.get("modal")==="dados") openDados();
  if (params.get("modal")==="encomendas") openGerir();
</script>

</body>
</html>