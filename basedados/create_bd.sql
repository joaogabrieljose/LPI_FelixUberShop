-- =========================================================
-- criar_bd.sql  (FelixUberShop)
-- Requisitos do enunciado:
-- - MySQL para todos os dados
-- - Utilizadores: cliente/cliente, funcionario/funcionario, admin/admin
-- - Produtos, promoções dinâmicas
-- - Carteira com transferência + auditoria
-- - Encomendas com identificador único + validação por funcionário
-- =========================================================

DROP DATABASE IF EXISTS felixubershop;
CREATE DATABASE felixubershop
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE felixubershop;

-- -----------------------------
-- 1) Config da Loja (site básico: contactos, horários, localização)
-- -----------------------------
CREATE TABLE loja_config (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nome_loja      VARCHAR(120) NOT NULL,
  morada         VARCHAR(200) NOT NULL,
  codigo_postal  VARCHAR(20)  NOT NULL,
  cidade         VARCHAR(80)  NOT NULL,
  pais           VARCHAR(80)  NOT NULL,
  email          VARCHAR(120),
  telefone       VARCHAR(40),
  horario_texto  VARCHAR(120) NOT NULL,
  criado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO loja_config (nome_loja, morada, codigo_postal, cidade, pais, email, telefone, horario_texto)
VALUES ('FelixUberShop', 'Travessa Fonseca Domingo', '8000-536', 'Faro', 'Portugal',
        'apoio@felixubershop.pt', '289 000 000', 'Dias úteis das 9h às 18h');

-- -----------------------------
-- 2) Utilizadores e Perfis
-- Perfis: visitante; cliente; funcionario; administrador
-- (visitante não precisa de registo)
-- -----------------------------
CREATE TABLE utilizadores (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password      VARCHAR(100) NOT NULL,          -- (para já texto simples; depois podes hash)
  perfil        ENUM('CLIENTE','FUNCIONARIO','ADMIN') NOT NULL,
  nome          VARCHAR(120),
  email         VARCHAR(120),
  telefone      VARCHAR(40),
  morada        VARCHAR(200),
  ativo         TINYINT(1) NOT NULL DEFAULT 1,
  criado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Utilizadores obrigatórios do enunciado
INSERT INTO utilizadores (username, password, perfil, nome, email)
VALUES
('cliente',     'cliente',     'CLIENTE',     'Cliente Demo',     'cliente@demo.pt'),
('funcionario', 'funcionario', 'FUNCIONARIO', 'Funcionário Demo', 'funcionario@demo.pt'),
('admin',       'admin',       'ADMIN',       'Administrador',    'admin@demo.pt');

-- -----------------------------
-- 3) Carteiras (saldo) + auditoria (movimentos)
-- - Cada cliente tem carteira com saldo
-- - Existe carteira especial da FelixUberShop
-- - Operações registadas para auditoria (data, valor, carteiras, etc.)
-- -----------------------------
CREATE TABLE carteiras (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  utilizador_id  INT NULL,
  tipo           ENUM('UTILIZADOR','LOJA') NOT NULL,
  saldo          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  criado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_carteira_user
    FOREIGN KEY (utilizador_id) REFERENCES utilizadores(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- carteira da loja (FelixUberShop)
INSERT INTO carteiras (utilizador_id, tipo, saldo) VALUES (NULL, 'LOJA', 0.00);

-- carteiras iniciais para os 3 utilizadores demo
INSERT INTO carteiras (utilizador_id, tipo, saldo)
SELECT id, 'UTILIZADOR', 20.00
FROM utilizadores
WHERE username IN ('cliente','funcionario','admin');

CREATE TABLE movimentos_carteira (
  id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
  tipo_operacao      ENUM('ADICIONAR','LEVANTAR','PAGAMENTO_ENCOMENDA','AJUSTE') NOT NULL,
  valor              DECIMAL(10,2) NOT NULL,
  carteira_origem_id INT NULL,
  carteira_destino_id INT NULL,
  descricao          VARCHAR(255),
  criado_em          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mov_origem
    FOREIGN KEY (carteira_origem_id) REFERENCES carteiras(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT fk_mov_destino
    FOREIGN KEY (carteira_destino_id) REFERENCES carteiras(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------
-- 4) Produtos (consulta por todos; gestão pelo admin)
-- -----------------------------
CREATE TABLE produtos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nome        VARCHAR(120) NOT NULL,
  descricao   VARCHAR(255),
  categoria   VARCHAR(80),
  preco       DECIMAL(10,2) NOT NULL,
  ativo       TINYINT(1) NOT NULL DEFAULT 1,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO produtos (nome, descricao, categoria, preco) VALUES
('Água 1,5L', 'Garrafa 1,5L', 'Bebidas', 0.79),
('Coca-Cola 1,5L', 'Garrafa 1,5L', 'Bebidas', 1.99),
('Massa Esparguete 500g', 'Embalagem 500g', 'Mercearia', 1.09),
('Arroz 1kg', 'Embalagem 1kg', 'Mercearia', 1.49),
('Leite Meio-Gordo 1L', 'Pacote 1L', 'Laticínios', 0.99),
('Iogurte Natural (pack)', 'Pack familiar', 'Laticínios', 1.59);

-- -----------------------------
-- 5) Promoções / Informações dinâmicas (admin gere)
-- -----------------------------
CREATE TABLE promocoes (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  titulo      VARCHAR(160) NOT NULL,
  descricao   TEXT NOT NULL,
  desconto_percent INT NULL,          -- opcional
  data_inicio DATE NULL,
  data_fim    DATE NULL,
  ativa       TINYINT(1) NOT NULL DEFAULT 1,
  criado_por  INT NULL,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_promocao_criado_por
    FOREIGN KEY (criado_por) REFERENCES utilizadores(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO promocoes (titulo, descricao, desconto_percent, data_inicio, data_fim, ativa, criado_por)
VALUES
('Poupe Esta Semana', 'Descontos em mercearia e bebidas selecionadas.', 10, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 1,
 (SELECT id FROM utilizadores WHERE username='admin' LIMIT 1));

-- -----------------------------
-- 6) Encomendas + Itens
-- - Gestão de encomendas
-- - Identificador único para validação por funcionário
-- -----------------------------
CREATE TABLE encomendas (
  id                BIGINT AUTO_INCREMENT PRIMARY KEY,
  identificador     CHAR(12) NOT NULL UNIQUE,  -- código único (ex.: AB12CD34EF56)
  cliente_id        INT NOT NULL,
  estado            ENUM('RASCUNHO','SUBMETIDA','PAGA','CANCELADA','VALIDADA') NOT NULL DEFAULT 'RASCUNHO',
  total             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  criado_em         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  validada_por      INT NULL,
  validada_em       DATETIME NULL,
  CONSTRAINT fk_encomenda_cliente
    FOREIGN KEY (cliente_id) REFERENCES utilizadores(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_encomenda_validada_por
    FOREIGN KEY (validada_por) REFERENCES utilizadores(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE encomenda_itens (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  encomenda_id  BIGINT NOT NULL,
  produto_id    INT NOT NULL,
  quantidade    INT NOT NULL DEFAULT 1,
  preco_unit    DECIMAL(10,2) NOT NULL,        -- preço no momento
  subtotal      DECIMAL(10,2) NOT NULL,        -- quantidade * preco_unit
  CONSTRAINT fk_item_encomenda
    FOREIGN KEY (encomenda_id) REFERENCES encomendas(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_item_produto
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Exemplo de encomenda demo (para testar)
INSERT INTO encomendas (identificador, cliente_id, estado, total)
VALUES ('AB12CD34EF56',
        (SELECT id FROM utilizadores WHERE username='cliente' LIMIT 1),
        'RASCUNHO',
        0.00);

-- Exemplo de item
INSERT INTO encomenda_itens (encomenda_id, produto_id, quantidade, preco_unit, subtotal)
VALUES (
  (SELECT id FROM encomendas WHERE identificador='AB12CD34EF56' LIMIT 1),
  (SELECT id FROM produtos WHERE nome='Água 1,5L' LIMIT 1),
  2,
  0.79,
  1.58
);

-- Atualizar total da encomenda demo
UPDATE encomendas
SET total = (
  SELECT IFNULL(SUM(subtotal),0)
  FROM encomenda_itens
  WHERE encomenda_id = encomendas.id
)
WHERE identificador='AB12CD34EF56';

-- Fim do criar_bd.sql