<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userIdObj = (Integer) session.getAttribute("userId");
String username = (String) session.getAttribute("username");

/* Restrição: qualquer FUNCIONARIO */
if (perfil == null || userIdObj == null || !perfil.equalsIgnoreCase("FUNCIONARIO")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}
int funcId = userIdObj.intValue();

// mensagens
String msg = request.getParameter("msg"); // ok | erro...

/* CARD: quantas validações já fez */
int totalValidadas = 0;
Connection conCnt = null;
PreparedStatement psCnt = null;
ResultSet rsCnt = null;

try{
  conCnt = dbConnect();
  psCnt = conCnt.prepareStatement("SELECT COUNT(*) AS t FROM encomendas WHERE validada_por=?");
  psCnt.setInt(1, funcId);
  rsCnt = dbQuery(conCnt, psCnt);
  if(rsCnt.next()) totalValidadas = rsCnt.getInt("t");
} catch(Exception e){
  // ignora
} finally {
  dbClose(rsCnt, psCnt, conCnt);
}

/* SELECT: TODAS as encomendas (para validar) */
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

/* SELECT: CLIENTES (para criar encomenda) */
Connection conCli = null;
PreparedStatement psCli = null;
ResultSet rsCli = null;

try{
  conCli = dbConnect();
  psCli = conCli.prepareStatement(
    "SELECT id, username, nome, email " +
    "FROM utilizadores " +
    "WHERE perfil='CLIENTE' AND ativo=1 " +
    "ORDER BY username ASC"
  );
  rsCli = dbQuery(conCli, psCli);
} catch(Exception e){
  out.print("Erro ao carregar clientes: " + e.getMessage());
}

/* SELECT: PRODUTOS (para criar encomenda) */
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

/* HISTÓRICO: VALIDAÇÕES */
Connection conHV = null;
PreparedStatement psHV = null;
ResultSet rsHV = null;

try{
  conHV = dbConnect();
  psHV = conHV.prepareStatement(
    "SELECT e.identificador, e.total, e.validada_em, u.username AS cliente_username " +
    "FROM encomendas e " +
    "JOIN utilizadores u ON u.id = e.cliente_id " +
    "WHERE e.validada_por=? AND e.validada_em IS NOT NULL " +
    "ORDER BY e.validada_em DESC LIMIT 50"
  );
  psHV.setInt(1, funcId);
  rsHV = dbQuery(conHV, psHV);
} catch(Exception e){ }

/* HISTÓRICO: CRIAÇÕES */
Connection conHC = null;
PreparedStatement psHC = null;
ResultSet rsHC = null;

try{
  conHC = dbConnect();
  psHC = conHC.prepareStatement(
    "SELECT e.identificador, e.total, e.criado_em, u.username AS cliente_username " +
    "FROM movimentos_carteira m " +
    "JOIN encomendas e ON m.descricao LIKE CONCAT('%', e.identificador, '%') " +
    "JOIN utilizadores u ON u.id = e.cliente_id " +
    "WHERE m.tipo_operacao='PAGAMENTO_ENCOMENDA' " +
    "  AND m.descricao LIKE CONCAT('%funcionario_id=', ?, '%') " +
    "ORDER BY e.criado_em DESC LIMIT 50"
  );
  psHC.setInt(1, funcId);
  rsHC = dbQuery(conHC, psHC);
} catch(Exception e){ }
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Funcionário - FelixUberShop</title>
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
      <p>Área do Funcionário</p>
    </div>
  </div>

  <div class="dash-user">
    <span class="pill"><%= username %></span>
  </div>
</header>

<div class="dash-layout">

  <aside class="dash-side">
    <nav class="menu">
      <a class="active" href="funcionario.jsp">Dashboard</a>
      <a href="#" id="abrirGerirEnc">Gerir Encomendas</a>
      <a href="#" id="abrirHistoricoEnc">Histórico</a>
      <a href="logout.jsp">Logout</a>
    </nav>
  </aside>

  <main class="dash-main">

    <section class="dash-hero">
      <div class="dash-hero-text">
        <h2>Painel do Funcionário</h2><br>
        
        <% if (msg != null) { %>
          <p style="font-weight:900; color:<%= (msg.startsWith("ok") ? "green" : "red") %>;">
            <%= (msg.startsWith("ok") ? "Operação realizada com sucesso." : ("Erro: " + msg)) %>
          </p>
        <% } %>

        <div class="dash-actions">
          <a class="btn" href="#" id="abrirGerirEnc2">Gerir agora</a>
          <a class="btn outline" href="#" id="abrirHistoricoEnc2">Ver histórico</a>
        </div>
      </div>
    </section>

    <section class="dash-cards">
      <article class="dash-card">
        <h3>Validações realizadas</h3>
        <p class="dash-big"><%= totalValidadas %></p>
        <p class="dash-muted">Total validadas por ti</p>
      </article>
    </section>

  </main>
</div>

<!-- ================= MODAL: GERIR ENCOMENDAS (VALIDAR + CRIAR) ================= -->
<div id="gerirEncModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gerir Encomendas</h2>
      <a href="#" class="modal-close" id="fecharGerirEnc">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-gerir-validar">Validar</button>
      <button type="button" class="tab-btn" data-tab="tab-gerir-criar">Criar Encomenda</button>
    </div>

    <!-- ====== TAB: VALIDAR ====== -->
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

    <!-- ====== TAB: CRIAR ====== -->
    <section id="tab-gerir-criar" class="tab-pane">
      <p class="muted">Seleciona o cliente e o produto (com preço). Depois indica a quantidade.</p>

      <form action="funcionario_encomenda.jsp" method="POST" class="form-grid">

        <div style="grid-column:1/-1;">
          <label>Cliente</label>
          <select name="cliente_id" required>
            <option value="">-- Selecionar cliente --</option>
            <%
              boolean temClientes = false;
              while (rsCli != null && rsCli.next()) {
                temClientes = true;
                int cid = rsCli.getInt("id");
                String ucli = rsCli.getString("username");
                String ncli = rsCli.getString("nome");
                String ecli = rsCli.getString("email");
            %>
              <option value="<%= cid %>">
                ID <%= cid %> | <%= ucli %><%= (ncli != null && !ncli.trim().isEmpty() ? (" — " + ncli) : "") %><%= (ecli != null && !ecli.trim().isEmpty() ? (" (" + ecli + ")") : "") %>
              </option>
            <%
              }
              if (!temClientes) {
            %>
              <option value="" disabled>Sem clientes ativos</option>
            <%
              }
            %>
          </select>
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

<!-- ================= MODAL: HISTÓRICO (VALIDAÇÕES + CRIAÇÕES) ================= -->
<div id="historicoEncModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Histórico</h2>
      <a href="#" class="modal-close" id="fecharHistoricoEnc">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-hist-validacoes">Validações</button>
      <button type="button" class="tab-btn" data-tab="tab-hist-criacoes">Criações</button>
    </div>

    <!-- ===== TAB: Validações ===== -->
    <section id="tab-hist-validacoes" class="tab-pane active">
      <div class="admin-table">
        <div class="row head">
          <div>Código</div><div>Cliente</div><div>Total</div><div>Data validada</div><div>Estado</div>
        </div>

        <%
          boolean temV = false;
          if (rsHV != null) {
            while (rsHV.next()) {
              temV = true;
              String cod = rsHV.getString("identificador");
              String cli = rsHV.getString("cliente_username");
              double tot = rsHV.getDouble("total");
              Timestamp dt = rsHV.getTimestamp("validada_em");
        %>
          <div class="row" style="grid-template-columns: 1fr 1fr 0.6fr 0.9fr 0.6fr;">
            <div><strong><%= cod %></strong></div>
            <div><%= (cli != null ? cli : "") %></div>
            <div><%= String.format("%.2f €", tot) %></div>
            <div><%= (dt != null ? dt.toString().substring(0,16) : "—") %></div>
            <div>VALIDADA</div>
          </div>
        <%
            }
          }
          if (!temV) {
        %>
          <div class="row"><div style="grid-column:1/-1;">Ainda não validaste encomendas.</div></div>
        <%
          }
        %>
      </div>
    </section>

    <!-- ===== TAB: Criações ===== -->
    <section id="tab-hist-criacoes" class="tab-pane">
      <div class="admin-table">
        <div class="row head">
          <div>Código</div><div>Cliente</div><div>Total</div><div>Data criação</div><div>Estado</div>
        </div>

        <%
          boolean temC = false;
          if (rsHC != null) {
            while (rsHC.next()) {
              temC = true;
              String cod = rsHC.getString("identificador");
              String cli = rsHC.getString("cliente_username");
              double tot = rsHC.getDouble("total");
              Timestamp dt = rsHC.getTimestamp("criado_em");
        %>
          <div class="row" style="grid-template-columns: 1fr 1fr 0.6fr 0.9fr 0.6fr;">
            <div><strong><%= cod %></strong></div>
            <div><%= (cli != null ? cli : "") %></div>
            <div><%= String.format("%.2f €", tot) %></div>
            <div><%= (dt != null ? dt.toString().substring(0,16) : "—") %></div>
            <div>PAGA</div>
          </div>
        <%
            }
          }
          if (!temC) {
        %>
          <div class="row"><div style="grid-column:1/-1;">Ainda não criaste encomendas para clientes.</div></div>
        <%
          }
        %>
      </div>
    </section>

  </div>
</div>

<script>
  // ====== abrir/fechar GERIR ======
  const gerirEncModal = document.getElementById("gerirEncModal");
  const abrirGerirEnc = document.getElementById("abrirGerirEnc");
  const abrirGerirEnc2 = document.getElementById("abrirGerirEnc2");
  const fecharGerirEnc = document.getElementById("fecharGerirEnc");

  function openGerir(e){ e.preventDefault(); gerirEncModal.classList.add("show"); }
  if (abrirGerirEnc) abrirGerirEnc.addEventListener("click", openGerir);
  if (abrirGerirEnc2) abrirGerirEnc2.addEventListener("click", openGerir);
  if (fecharGerirEnc) fecharGerirEnc.addEventListener("click", (e)=>{ e.preventDefault(); gerirEncModal.classList.remove("show"); });
  gerirEncModal.addEventListener("click", (e)=>{ if(e.target.id==="gerirEncModal") gerirEncModal.classList.remove("show"); });

  // tabs scoped do gerir
  (function initTabsGerir(){
    const box = gerirEncModal.querySelector(".modal-box");
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
  })();

  // ====== abrir/fechar HISTÓRICO ======
  const historicoEncModal = document.getElementById("historicoEncModal");
  const abrirHistoricoEnc = document.getElementById("abrirHistoricoEnc");
  const abrirHistoricoEnc2 = document.getElementById("abrirHistoricoEnc2");
  const fecharHistoricoEnc = document.getElementById("fecharHistoricoEnc");

  function openHist(e){ e.preventDefault(); historicoEncModal.classList.add("show"); }
  if (abrirHistoricoEnc) abrirHistoricoEnc.addEventListener("click", openHist);
  if (abrirHistoricoEnc2) abrirHistoricoEnc2.addEventListener("click", openHist);
  if (fecharHistoricoEnc) fecharHistoricoEnc.addEventListener("click", (e)=>{ e.preventDefault(); historicoEncModal.classList.remove("show"); });
  historicoEncModal.addEventListener("click", (e)=>{ if(e.target.id==="historicoEncModal") historicoEncModal.classList.remove("show"); });

  // tabs scoped do histórico
  (function initTabsHistorico(){
    const box = historicoEncModal.querySelector(".modal-box");
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
  })();

  // ESC fecha
  document.addEventListener("keydown", (e)=>{
    if(e.key==="Escape"){
      gerirEncModal.classList.remove("show");
      historicoEncModal.classList.remove("show");
    }
  });
</script>

</body>
</html>