<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");
String username = (String) session.getAttribute("username");

/*  Restrição: qualquer FUNCIONARIO */
if (perfil == null || userId == null || !perfil.equalsIgnoreCase("FUNCIONARIO")) {
  response.sendRedirect("index.jsp?acesso=negado");
  return;
}

int funcId = userId.intValue();

// mensagens
String msg = request.getParameter("msg"); // ok | nao_encontrada | nao_pode_validar | erro

// cards: quantas validações já fez
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

/*  SELECT: TODAS as encomendas (como admin) */
Connection conSel = null;
PreparedStatement psSel = null;
ResultSet rsSel = null;

try{
  conSel = dbConnect();
  psSel = conSel.prepareStatement(
    "SELECT e.id, e.identificador, e.estado, e.total, e.criado_em, u.username " +
    "FROM encomendas e " +
    "JOIN utilizadores u ON u.id = e.cliente_id " +
    "ORDER BY e.criado_em DESC LIMIT 100"
  );
  rsSel = dbQuery(conSel, psSel);
} catch(Exception e){
  out.print("Erro ao carregar encomendas: " + e.getMessage());
}

/* histórico (para a MODAL) */
Connection conH = null;
PreparedStatement psH = null;
ResultSet rsH = null;

try{
  conH = dbConnect();
  psH = conH.prepareStatement(
    "SELECT identificador, total, validada_em " +
    "FROM encomendas WHERE validada_por=? " +
    "ORDER BY validada_em DESC LIMIT 20"
  );
  psH.setInt(1, funcId);
  rsH = dbQuery(conH, psH);
} catch(Exception e){
  // ignora
}
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
      <a href="#" id="abrirValidarEnc">Validar Encomenda</a>
      <a href="#" id="abrirHistoricoEnc">Histórico</a>
      <a href="logout.jsp">Logout</a>
    </nav>
  </aside>

  <main class="dash-main">

    <section class="dash-hero">
      <div class="dash-hero-text">
        <h2>Painel do Funcionário</h2>
        <p>Escolhe a encomenda na lista e valida (só valida se estiver <strong>PAGA</strong>).</p>

        <% if (msg != null) { %>
          <p style="font-weight:900; color:<%= "ok".equals(msg) ? "green" : "red" %>;">
            <%= "ok".equals(msg) ? "Encomenda validada com sucesso." : ("Erro: " + msg) %>
          </p>
        <% } %>

        <div class="dash-actions">
          <a class="btn" href="#" id="abrirValidarEnc2">Validar agora</a>
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

      <article class="dash-card">
        <h3>Regra</h3>
        <p class="dash-big">PAGA → VALIDADA</p>
        <p class="dash-muted">Só valida se estiver PAGA</p>
      </article>

      <article class="dash-card">
        <h3>Ajuda</h3>
        <p class="dash-big">Lista</p>
        <p class="dash-muted">Mostra todas as encomendas</p>
      </article>
    </section>

  </main>
</div>

<!-- ================= MODAL: VALIDAR ENCOMENDA ================= -->
<div id="validarEncModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Validar Encomenda</h2>
      <a href="#" class="modal-close" id="fecharValidarEnc">✕</a>
    </div>

    <div class="tabs">
      <button type="button" class="tab-btn active" data-tab="tab-val-1">Validar</button>
      <button type="button" class="tab-btn" data-tab="tab-val-2">Regras</button>
    </div>

    <section id="tab-val-1" class="tab-pane active">
      <p class="muted">Seleciona uma encomenda. O sistema só valida se ela estiver <strong>PAGA</strong>.</p>

      <form action="funcionario_validar.jsp" method="POST" class="form-grid">
        <div style="grid-column:1/-1;">
          <label>Encomendas (todas)</label>

          <select name="encomenda_id" required>
            <option value="">-- Selecionar encomenda --</option>

            <%
              boolean tem = false;
              while (rsSel != null && rsSel.next()) {
                tem = true;
                long encId = rsSel.getLong("id");
                String cod = rsSel.getString("identificador");
                String est = rsSel.getString("estado");
                String cli = rsSel.getString("username");
                double tot = rsSel.getDouble("total");
                Timestamp dt = rsSel.getTimestamp("criado_em");
            %>
              <option value="<%= encId %>">
                <%= cod %> | <%= cli %> | <%= est %> | <%= String.format("%.2f €", tot) %>
                <%= (dt != null ? (" | " + dt.toString().substring(0,16)) : "") %>
              </option>
            <%
              }
              if (!tem) {
            %>
              <option value="" disabled>Sem encomendas.</option>
            <%
              }
            %>

          </select>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-submit">Validar</button>
        </div>
      </form>
    </section>

    <section id="tab-val-2" class="tab-pane">
      <h3>Regras</h3>
      <p class="muted">
        • Só é possível validar se o estado for <strong>PAGA</strong>.<br>
        • Ao validar, o estado passa para <strong>VALIDADA</strong> e ficam guardados: <code>validada_por</code> e <code>validada_em</code>.<br>
        • O cliente passa a ver a encomenda como <strong>VALIDADA</strong>.
      </p>
    </section>

  </div>
</div>

<!-- ================= MODAL: HISTÓRICO ================= -->
<div id="historicoEncModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Histórico de Validações</h2>
      <a href="#" class="modal-close" id="fecharHistoricoEnc">✕</a>
    </div>

    <div class="admin-table">
      <div class="row head">
        <div>Código</div><div>Total</div><div>Validada em</div><div>Estado</div>
      </div>

      <%
        boolean temH = false;
        if (rsH != null) {
          while (rsH.next()) {
            temH = true;
            String cod = rsH.getString("identificador");
            double tot = rsH.getDouble("total");
            Timestamp dt = rsH.getTimestamp("validada_em");
      %>
        <div class="row" style="grid-template-columns: 1fr 0.6fr 0.9fr 0.6fr;">
          <div><strong><%= cod %></strong></div>
          <div><%= String.format("%.2f €", tot) %></div>
          <div><%= (dt != null ? dt.toString().substring(0,16) : "—") %></div>
          <div>VALIDADA</div>
        </div>
      <%
          }
        }
        if (!temH) {
      %>
        <div class="row"><div style="grid-column:1/-1;">Ainda não validaste encomendas.</div></div>
      <%
        }
      %>
    </div>

  </div>
</div>

<script>
  const validarEncModal = document.getElementById("validarEncModal");
  const abrirValidarEnc = document.getElementById("abrirValidarEnc");
  const abrirValidarEnc2 = document.getElementById("abrirValidarEnc2");
  const fecharValidarEnc = document.getElementById("fecharValidarEnc");

  function openValidar(e){ e.preventDefault(); validarEncModal.classList.add("show"); }
  if (abrirValidarEnc) abrirValidarEnc.addEventListener("click", openValidar);
  if (abrirValidarEnc2) abrirValidarEnc2.addEventListener("click", openValidar);
  if (fecharValidarEnc) fecharValidarEnc.addEventListener("click", (e)=>{ e.preventDefault(); validarEncModal.classList.remove("show"); });
  validarEncModal.addEventListener("click", (e)=>{ if(e.target.id==="validarEncModal") validarEncModal.classList.remove("show"); });

  const historicoEncModal = document.getElementById("historicoEncModal");
  const abrirHistoricoEnc = document.getElementById("abrirHistoricoEnc");
  const abrirHistoricoEnc2 = document.getElementById("abrirHistoricoEnc2");
  const fecharHistoricoEnc = document.getElementById("fecharHistoricoEnc");

  function openHist(e){ e.preventDefault(); historicoEncModal.classList.add("show"); }
  if (abrirHistoricoEnc) abrirHistoricoEnc.addEventListener("click", openHist);
  if (abrirHistoricoEnc2) abrirHistoricoEnc2.addEventListener("click", openHist);
  if (fecharHistoricoEnc) fecharHistoricoEnc.addEventListener("click", (e)=>{ e.preventDefault(); historicoEncModal.classList.remove("show"); });
  historicoEncModal.addEventListener("click", (e)=>{ if(e.target.id==="historicoEncModal") historicoEncModal.classList.remove("show"); });

  document.addEventListener("keydown", (e)=>{
    if(e.key==="Escape"){
      validarEncModal.classList.remove("show");
      historicoEncModal.classList.remove("show");
    }
  });

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
  initTabs("validarEncModal");
</script>

<%
dbClose(rsSel, psSel, conSel);
dbClose(rsH, psH, conH);
%>

</body>
</html>