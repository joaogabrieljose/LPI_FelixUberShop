<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="../basedados/basedados.h" %>

<%-- Restrição de acesso: apenas CLIENTE --%>
<%
String perfil = (String) session.getAttribute("perfil");
Integer userId = (Integer) session.getAttribute("userId");

if (perfil == null || userId == null || !perfil.equalsIgnoreCase("CLIENTE")) {
    response.sendRedirect("index.jsp?acesso=negado");
    return;
}

String username = (String) session.getAttribute("username");
%>

<%-- Buscar dados pessoais na BD --%>
<%
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nome = "";
String email = "";
String telefone = "";
String morada = "";

try {
    con = dbConnect();
    ps = con.prepareStatement("SELECT nome, email, telefone, morada FROM utilizadores WHERE id=? LIMIT 1");
    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        nome = rs.getString("nome") != null ? rs.getString("nome") : "";
        email = rs.getString("email") != null ? rs.getString("email") : "";
        telefone = rs.getString("telefone") != null ? rs.getString("telefone") : "";
        morada = rs.getString("morada") != null ? rs.getString("morada") : "";
    }
} catch (Exception e) {
    out.print("Erro ao carregar dados: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}
%>

<%-- Buscar produtos na BD (para o modal) --%>
<%
Connection conP = null;
PreparedStatement psP = null;
ResultSet rsP = null;

try {
    conP = dbConnect();
    psP = conP.prepareStatement(
        "SELECT id, nome, descricao, categoria, preco " +
        "FROM produtos WHERE ativo=1 ORDER BY categoria, nome"
    );
    rsP = dbQuery(conP, psP);
} catch (Exception e) {
    out.print("Erro ao carregar produtos: " + e.getMessage());
}
%>

<%-- Consultar saldo da carteira do utilizador --%>
<%
Connection conS = null;
PreparedStatement psS = null;
ResultSet rsS = null;

int carteiraId = 0;
double saldoAtual = 0.0;

try {
    conS = dbConnect();
    psS = conS.prepareStatement(
        "SELECT id, saldo FROM carteiras WHERE utilizador_id=? AND tipo='UTILIZADOR' LIMIT 1"
    );
    psS.setInt(1, userId);
    rsS = dbQuery(conS, psS);

    if (rsS.next()) {
        carteiraId = rsS.getInt("id");
        saldoAtual = rsS.getDouble("saldo");
    }
} catch (Exception e) {
    out.print("Erro ao carregar saldo: " + e.getMessage());
} finally {
    dbClose(rsS, psS, conS);
}
%>

<%-- Consultar encomendas do cliente (para o modal de encomendas) --%>
<%
Connection conE = null;
PreparedStatement psE = null;
ResultSet rsE = null;

try {
    conE = dbConnect();
    psE = conE.prepareStatement(
        "SELECT id, identificador, estado, total, criado_em " +
        "FROM encomendas WHERE cliente_id=? ORDER BY criado_em DESC LIMIT 20"
    );
    psE.setInt(1, userId);
    rsE = dbQuery(conE, psE);
} catch (Exception e) {
    out.print("Erro ao carregar encomendas: " + e.getMessage());
}
%>

<%-- COUNT de encomendas (para o card) --%>
<%
int totalEncomendas = 0;

Connection conCnt = null;
PreparedStatement psCnt = null;
ResultSet rsCnt = null;

try {
    conCnt = dbConnect();
    psCnt = conCnt.prepareStatement("SELECT COUNT(*) AS total FROM encomendas WHERE cliente_id=?");
    psCnt.setInt(1, userId);
    rsCnt = dbQuery(conCnt, psCnt);
    if (rsCnt.next()) totalEncomendas = rsCnt.getInt("total");
} catch (Exception e) {
    out.print("Erro ao contar encomendas: " + e.getMessage());
} finally {
    dbClose(rsCnt, psCnt, conCnt);
}
%>

<%-- Últimas encomendas (para a tabela do dashboard) --%>
<%
Connection conUlt = null;
PreparedStatement psUlt = null;
ResultSet rsUlt = null;

try {
    conUlt = dbConnect();
    psUlt = conUlt.prepareStatement(
        "SELECT identificador, estado, total, criado_em " +
        "FROM encomendas WHERE cliente_id=? ORDER BY criado_em DESC LIMIT 5"
    );
    psUlt.setInt(1, userId);
    rsUlt = dbQuery(conUlt, psUlt);
} catch (Exception e) {
    out.print("Erro ao carregar últimas encomendas: " + e.getMessage());
}
%>

<%-- ativas Promoções (para o modal) --%>
<%
Connection conPr = null;
PreparedStatement psPr = null;
ResultSet rsPr = null;

try {
    conPr = dbConnect();
    psPr = conPr.prepareStatement(
        "SELECT titulo, descricao, desconto_percent, data_inicio, data_fim " +
        "FROM promocoes WHERE ativa=1 " +
        "ORDER BY criado_em DESC LIMIT 10"
    );
    rsPr = dbQuery(conPr, psPr);
} catch (Exception e) {
    out.print("Erro ao carregar promoções: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Dashboard Cliente - FelixUberShop</title>
  <link rel="stylesheet" href="cliente.css">
  <link rel="stylesheet" href="cliente_dados_pessoais.css">
  <link rel="stylesheet" href="cliente_produtos.css">
</head>
<body>

<header class="dash-top">
  <div class="dash-brand">
    <a class="brand" href="index.jsp">
      <img src="legumes.png" class="logo" alt="FelixUberShop">
    </a>
    <div>
      <h1>FelixUberShop</h1>
      <p>Área do Cliente</p>
    </div>
  </div>

  <div class="dash-user">
    <span class="pill">👤 <%= username %></span>
  </div>
</header>

<div class="dash-layout">

  <aside class="dash-side">
    <nav class="menu">
      <a class="active" href="cliente.jsp">Dashboard</a>
      <a href="#" id="abrirDadosLink">dados pessoais</a>
      <a href="#" id="abrirProdutosLink">Consultar produtos</a>
      <a href="#" id="abrirSaldoLink">Carteira</a>
      <a href="#" id="abrirEncomendasLink">Encomendas</a>
      <a href="logout.jsp">logout</a>
    </nav>
  </aside>

  <main class="dash-main">

    <section class="dash-hero">
      <div class="dash-hero-text">
        <h2>Bem-vindo(a), <%= username %>!</h2>
        <p>Veja as suas encomendas, saldo e promoções da semana num só lugar.</p>
        <div class="dash-actions">
          <a class="btn" href="#" id="abrirProdutosLinkHero">Ver Produtos</a>
          <a class="btn outline" href="#" id="abrirPromocoesLink">Ver Promoções</a>
        </div>
      </div>
    </section>

    <%-- Cards dinâmicos (saldo + encomendas) --%>
    <section class="dash-cards">
      <article class="dash-card">
        <h3>Saldo</h3>
        <p class="dash-big"><%= String.format("€ %.2f", saldoAtual) %></p>
        <p class="dash-muted">Carteira do cliente</p>
      </article>

      <article class="dash-card">
        <h3>Encomendas</h3>
        <p class="dash-big"><%= totalEncomendas %></p>
        <p class="dash-muted">Encomendas feitas</p>
      </article>

      <article class="dash-card">
        <h3>Promoções</h3>
        <p class="dash-big">0</p>
        <p class="dash-muted">Ativas esta semana</p>
      </article>
    </section>

    <%-- Últimas encomendas (dinâmico) --%>
    <section class="dash-section">
      <div class="dash-section-top">
        <h3>Últimas encomendas</h3>
        <a href="#" class="link" id="abrirEncomendasLink2">Ver todas</a>
      </div>

      <div class="dash-table">
        <div class="row head">
          <div>ID</div><div>Estado</div><div>Total</div><div>Data</div>
        </div>

        <%
          boolean temUlt = false;
          if (rsUlt != null) {
            while (rsUlt.next()) {
              temUlt = true;
              String cod = rsUlt.getString("identificador");
              String est = rsUlt.getString("estado");
              double tot = rsUlt.getDouble("total");
              Timestamp dt = rsUlt.getTimestamp("criado_em");
        %>
              <div class="row">
                <div><%= cod %></div>
                <div><%= est %></div>
                <div><%= String.format("€ %.2f", tot) %></div>
                <div><%= (dt != null ? dt.toString().substring(0,10) : "") %></div>
              </div>
        <%
            }
          }
          if (!temUlt) {
        %>
            <div class="row">
              <div style="grid-column:1/-1;">Ainda não tem encomendas.</div>
            </div>
        <%
          }
        %>
      </div>
    </section>

  </main>
</div>


<!-- MODAL: Dados Pessoais -->
<div id="dadosModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>Dados Pessoais</h2>
      <a href="#" class="modal-close" id="fecharDadosLink">✕</a>
    </div>

    <form action="dados_pessoais_update.jsp" method="POST" class="login-form">
      <label for="nome">Nome</label>
      <input type="text" id="nome" name="nome" value="<%= nome %>" required>

      <label for="email">Email</label>
      <input type="email" id="email" name="email" value="<%= email %>">

      <label for="telefone">Telefone</label>
      <input type="text" id="telefone" name="telefone" value="<%= telefone %>">

      <label for="morada">Morada</label>
      <input type="text" id="morada" name="morada" value="<%= morada %>">

      <button type="submit" class="btn-submit">Guardar alterações</button>
    </form>

    <p class="modal-note">
      * Os dados são guardados na base de dados.
    </p>
  </div>
</div>

<script>
  const dadosModal = document.getElementById("dadosModal");
  const abrirDados = document.getElementById("abrirDadosLink");
  const fecharDados = document.getElementById("fecharDadosLink");

  if (abrirDados) abrirDados.addEventListener("click", function(e){
    e.preventDefault();
    dadosModal.classList.add("show");
  });

  if (fecharDados) fecharDados.addEventListener("click", function(e){
    e.preventDefault();
    dadosModal.classList.remove("show");
  });

  dadosModal.addEventListener("click", function(e){
    if(e.target.id === "dadosModal") dadosModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if(e.key === "Escape") dadosModal.classList.remove("show");
  });
</script>

<!-- MODAL: Consultar Produtos -->
<div id="produtosModal" class="modal">
  <div class="modal-box modal-wide">
    <div class="modal-top">
      <h2>Produtos disponíveis</h2>
      <a href="#" class="modal-close" id="fecharProdutosLink">✕</a>
    </div>

    <div class="produtos-modal-grid">
      <%
        if (rsP != null) {
          while (rsP.next()) {
            String nomeP = rsP.getString("nome");
            String descP = rsP.getString("descricao");
            String catP = rsP.getString("categoria");
            double precoP = rsP.getDouble("preco");
      %>
            <article class="produto-card">
              <p class="produto-cat"><%= (catP != null ? catP : "Geral") %></p>
              <h3 class="produto-nome"><%= nomeP %></h3>
              <p class="produto-desc"><%= (descP != null ? descP : "") %></p>
              <div class="produto-footer">
                <span class="produto-preco"><%= String.format("%.2f €", precoP) %></span>
                
              </div>
            </article>
      <%
          }
        } else {
      %>
          <p>Não foi possível carregar os produtos.</p>
      <%
        }
      %>
    </div>
  </div>
</div>

<%
dbClose(rsP, psP, conP);
%>

<script id="fix-produtos-modal">
  const produtosModal = document.getElementById("produtosModal");
  const abrirProdutos = document.getElementById("abrirProdutosLink");
  const abrirProdutosHero = document.getElementById("abrirProdutosLinkHero");
  const fecharProdutos = document.getElementById("fecharProdutosLink");

  function abrirProdutosFn(e){
    e.preventDefault();
    produtosModal.classList.add("show");
  }

  if (abrirProdutos) abrirProdutos.addEventListener("click", abrirProdutosFn);
  if (abrirProdutosHero) abrirProdutosHero.addEventListener("click", abrirProdutosFn);

  if (fecharProdutos) {
    fecharProdutos.addEventListener("click", function(e){
      e.preventDefault();
      produtosModal.classList.remove("show");
    });
  }

  produtosModal.addEventListener("click", function(e){
    if (e.target.id === "produtosModal") produtosModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if (e.key === "Escape") produtosModal.classList.remove("show");
  });
</script>

<!-- MODAL: Carteira -->
<div id="saldoModal" class="modal">
  <div class="modal-box">
    <div class="modal-top">
      <h2>Carteira</h2>
      <a href="#" class="modal-close" id="fecharSaldoLink">✕</a>
    </div>

    <div class="saldo-box">
      <p class="saldo-label">Saldo atual</p>
      <p class="saldo-valor"><%= String.format("%.2f €", saldoAtual) %></p>
    </div>

    <form action="cliente_saldo.jsp" method="POST" class="saldo-form">
      <input type="hidden" name="acao" value="ADICIONAR">
      <label>Depositar saldo (€)</label>
      <input type="number" name="valor" step="0.01" min="0.01" required>
      <button type="submit" class="btn-submit">Adicionar</button>
    </form>

    <form action="cliente_saldo.jsp" method="POST" class="saldo-form">
      <input type="hidden" name="acao" value="LEVANTAR">
      <label>Levantar saldo (€)</label>
      <input type="number" name="valor" step="0.01" min="0.01" required>
      <button type="submit" class="btn-submit danger">Levantar</button>
    </form>

    <p class="modal-note">
      * As operações são registadas em auditoria (movimentos da carteira).
    </p>
  </div>
</div>

<script>
  const saldoModal = document.getElementById("saldoModal");
  const abrirSaldo = document.getElementById("abrirSaldoLink");
  const fecharSaldo = document.getElementById("fecharSaldoLink");

  if (abrirSaldo) {
    abrirSaldo.addEventListener("click", function(e){
      e.preventDefault();
      saldoModal.classList.add("show");
    });
  }
  if (fecharSaldo) {
    fecharSaldo.addEventListener("click", function(e){
      e.preventDefault();
      saldoModal.classList.remove("show");
    });
  }

  saldoModal.addEventListener("click", function(e){
    if(e.target.id === "saldoModal") saldoModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if(e.key === "Escape") saldoModal.classList.remove("show");
  });
</script>

<!-- MODAL: Gestão de Encomendas -->
<div id="encomendasModal" class="modal">
  <div class="modal-box modal-xl">
    <div class="modal-top">
      <h2>Gestão de Encomendas</h2>
      <a href="#" class="modal-close" id="fecharEncomendasLink">✕</a>
    </div>

    <div class="encomendas-top-actions">
      <form action="cliente_encomenda_nova.jsp" method="POST" style="display:inline;">
        <button type="submit" class="btn-submit">+ Nova encomenda</button>
      </form>
      <p class="modal-note">
        * Editar/Cancelar apenas encomendas em estado <strong>RASCUNHO</strong>.
      </p>
    </div>

    <div class="encomendas-table">
      <div class="row head">
        <div>Código</div><div>Estado</div><div>Total</div><div>Data</div><div>Ações</div>
      </div>

      <%
        if (rsE != null) {
          boolean tem = false;
          while (rsE.next()) {
            tem = true;
            long encId = rsE.getLong("id");
            String cod = rsE.getString("identificador");
            String est = rsE.getString("estado");
            double tot = rsE.getDouble("total");
            Timestamp data = rsE.getTimestamp("criado_em");
      %>
            <div class="row">
              <div><strong><%= cod %></strong></div>
              <div><%= est %></div>
              <div><%= String.format("%.2f €", tot) %></div>
              <div><%= (data != null ? data.toString().substring(0,16) : "") %></div>

              <div class="acoes">
                <form action="cliente_encomenda_ver.jsp" method="GET" class="inline-form">
                  <input type="hidden" name="id" value="<%= encId %>">
                  <button type="submit" class="btn-mini">Ver</button>
                </form>

                <% if ("RASCUNHO".equalsIgnoreCase(est)) { %>
                  <form action="cliente_encomenda_detalhes.jsp" method="GET" class="inline-form">
                    <input type="hidden" name="id" value="<%= encId %>">
                    <button type="submit" class="btn-mini">Editar</button>
                  </form>

                  <% if (tot > 0) { %>
                    <form action="cliente_paga_encomenda.jsp" method="POST" class="inline-form">
                      <input type="hidden" name="id" value="<%= encId %>">
                      <button type="submit" class="btn-mini pay">Pagar</button>
                    </form>
                  <% } %>

                  <form action="#" method="POST" class="inline-form">
                    <input type="hidden" name="id" value="<%= encId %>">
                    <button type="submit" class="btn-mini danger">Cancelar</button>
                  </form>
                <% } %>
              </div>
            </div>
      <%
          }
          if (!tem) {
      %>
            <div class="row"><div style="grid-column:1/-1;">Ainda não tem encomendas.</div></div>
      <%
          }
        } else {
      %>
          <div class="row"><div style="grid-column:1/-1;">Erro ao carregar encomendas.</div></div>
      <%
        }
      %>
    </div>
  </div>
</div>


<script>
  const encomendasModal = document.getElementById("encomendasModal");
  const abrirEnc = document.getElementById("abrirEncomendasLink");
  const abrirEnc2 = document.getElementById("abrirEncomendasLink2");
  const fecharEnc = document.getElementById("fecharEncomendasLink");

  function abrirEncFn(e){ e.preventDefault(); encomendasModal.classList.add("show"); }

  if (abrirEnc) abrirEnc.addEventListener("click", abrirEncFn);
  if (abrirEnc2) abrirEnc2.addEventListener("click", abrirEncFn);

  if (fecharEnc) fecharEnc.addEventListener("click", (e)=>{ e.preventDefault(); encomendasModal.classList.remove("show"); });

  encomendasModal.addEventListener("click", (e)=>{ if(e.target.id==="encomendasModal") encomendasModal.classList.remove("show"); });
</script>



<!-- MODAL: Promoções -->
<div id="promocoesModal" class="modal">
  <div class="modal-box modal-wide">
    <div class="modal-top">
      <h2>Promoções Ativas</h2>
      <a href="#" class="modal-close" id="fecharPromocoesLink">✕</a>
    </div>

    <div class="dash-section" style="box-shadow:none;border:none;padding:0;">
      <%
        boolean temPromo = false;
        if (rsPr != null) {
          while (rsPr.next()) {
            temPromo = true;

            String titulo = rsPr.getString("titulo");
            String descricao = rsPr.getString("descricao");
            int desconto = rsPr.getInt("desconto_percent");
            boolean descNull = rsPr.wasNull();

            Date di = rsPr.getDate("data_inicio");
            Date df = rsPr.getDate("data_fim");
      %>

        <article class="dash-card" style="margin-bottom:12px;">
          <h3 style="margin-bottom:6px;"><%= titulo %></h3>

          <p class="dash-muted" style="margin-bottom:10px;">
            <%= (descricao != null ? descricao : "") %>
          </p>

          <p style="margin:0;font-weight:900;">
            <%= (descNull ? "" : ("Desconto: " + desconto + "%")) %>
          </p>

          <p class="dash-muted" style="margin:6px 0 0;">
            <strong>Período:</strong>
            <%= (di != null ? di.toString() : "—") %>
            →
            <%= (df != null ? df.toString() : "—") %>
          </p>
        </article>

      <%
          }
        }

        if (!temPromo) {
      %>
        <div class="dash-card">
          <h3>Sem promoções no momento</h3>
          <p class="dash-muted">Volte mais tarde para ver novidades.</p>
        </div>
      <%
        }
      %>
    </div>

  </div>
</div>

<script>
  const promocoesModal = document.getElementById("promocoesModal");
  const abrirPromocoes = document.getElementById("abrirPromocoesLink");
  const fecharPromocoes = document.getElementById("fecharPromocoesLink");

  if (abrirPromocoes) {
    abrirPromocoes.addEventListener("click", function(e){
      e.preventDefault();
      promocoesModal.classList.add("show");
    });
  }

  if (fecharPromocoes) {
    fecharPromocoes.addEventListener("click", function(e){
      e.preventDefault();
      promocoesModal.classList.remove("show");
    });
  }

  promocoesModal.addEventListener("click", function(e){
    if (e.target.id === "promocoesModal") promocoesModal.classList.remove("show");
  });

  document.addEventListener("keydown", function(e){
    if (e.key === "Escape") promocoesModal.classList.remove("show");
  });
</script>

</body>
</html>