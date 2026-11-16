CREATE DATABASE IF NOT EXISTS condofacil
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE condofacil;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS movimentacoes, pagamentos, despesas, cobrancas,
  usuario_grupo, usuarios, grupos_usuarios, moradias, funcionarios,
  moradores, unidades, condominios;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE condominios (
  id_condominio INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  endereco VARCHAR(220) NOT NULL,
  cnpj VARCHAR(18) UNIQUE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE unidades (
  id_unidade INT AUTO_INCREMENT PRIMARY KEY,
  id_condominio INT NOT NULL,
  bloco VARCHAR(30) NOT NULL,
  numero VARCHAR(20) NOT NULL,
  tipo VARCHAR(30) DEFAULT 'APARTAMENTO',
  UNIQUE KEY uk_unidade (id_condominio, bloco, numero),
  CONSTRAINT fk_unidade_condominio FOREIGN KEY (id_condominio)
    REFERENCES condominios(id_condominio)
) ENGINE=InnoDB;

CREATE TABLE moradores (
  id_morador INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(140) NOT NULL,
  cpf CHAR(11) NOT NULL UNIQUE,
  email VARCHAR(140),
  telefone VARCHAR(20),
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE moradias (
  id_moradia INT AUTO_INCREMENT PRIMARY KEY,
  id_morador INT NOT NULL,
  id_unidade INT NOT NULL,
  tipo_vinculo ENUM('PROPRIETARIO','INQUILINO','DEPENDENTE') NOT NULL,
  data_inicio DATE NOT NULL,
  data_fim DATE NULL,
  CONSTRAINT fk_moradia_morador FOREIGN KEY (id_morador) REFERENCES moradores(id_morador),
  CONSTRAINT fk_moradia_unidade FOREIGN KEY (id_unidade) REFERENCES unidades(id_unidade),
  CONSTRAINT chk_moradia_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio)
) ENGINE=InnoDB;

CREATE TABLE funcionarios (
  id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
  id_condominio INT NOT NULL,
  nome VARCHAR(140) NOT NULL,
  cargo VARCHAR(80) NOT NULL,
  email VARCHAR(140),
  ativo BOOLEAN DEFAULT TRUE,
  CONSTRAINT fk_func_condominio FOREIGN KEY (id_condominio) REFERENCES condominios(id_condominio)
) ENGINE=InnoDB;

CREATE TABLE grupos_usuarios (
  id_grupo INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(50) NOT NULL UNIQUE,
  descricao VARCHAR(180)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  id_usuario CHAR(36) PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  email VARCHAR(140) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE usuario_grupo (
  id_usuario CHAR(36) NOT NULL,
  id_grupo INT NOT NULL,
  PRIMARY KEY (id_usuario, id_grupo),
  CONSTRAINT fk_ug_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
  CONSTRAINT fk_ug_grupo FOREIGN KEY (id_grupo) REFERENCES grupos_usuarios(id_grupo)
) ENGINE=InnoDB;

CREATE TABLE cobrancas (
  id_cobranca INT AUTO_INCREMENT PRIMARY KEY,
  id_unidade INT NOT NULL,
  descricao VARCHAR(160) NOT NULL,
  valor DECIMAL(12,2) NOT NULL,
  multa DECIMAL(12,2) NOT NULL DEFAULT 0,
  vencimento DATE NOT NULL,
  status ENUM('PENDENTE','PARCIAL','PAGA','CANCELADA') NOT NULL DEFAULT 'PENDENTE',
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cobranca_unidade FOREIGN KEY (id_unidade) REFERENCES unidades(id_unidade),
  CONSTRAINT chk_cobranca_valor CHECK (valor > 0),
  INDEX idx_cobranca_status_venc (status, vencimento),
  INDEX idx_cobranca_unidade (id_unidade)
) ENGINE=InnoDB;

CREATE TABLE pagamentos (
  id_pagamento CHAR(36) PRIMARY KEY,
  id_cobranca INT NOT NULL,
  valor DECIMAL(12,2) NOT NULL,
  data_pagamento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  forma_pagamento ENUM('PIX','DINHEIRO','BOLETO','TRANSFERENCIA') NOT NULL,
  CONSTRAINT fk_pagamento_cobranca FOREIGN KEY (id_cobranca) REFERENCES cobrancas(id_cobranca),
  CONSTRAINT chk_pagamento_valor CHECK (valor > 0),
  INDEX idx_pagamento_cobranca_data (id_cobranca, data_pagamento)
) ENGINE=InnoDB;

CREATE TABLE despesas (
  id_despesa INT AUTO_INCREMENT PRIMARY KEY,
  id_condominio INT NOT NULL,
  descricao VARCHAR(160) NOT NULL,
  categoria VARCHAR(80) NOT NULL,
  valor DECIMAL(12,2) NOT NULL,
  data_despesa DATE NOT NULL,
  CONSTRAINT fk_despesa_condominio FOREIGN KEY (id_condominio) REFERENCES condominios(id_condominio),
  CONSTRAINT chk_despesa_valor CHECK (valor > 0),
  INDEX idx_despesa_condominio_data (id_condominio, data_despesa)
) ENGINE=InnoDB;

CREATE TABLE movimentacoes (
  id_movimentacao CHAR(36) PRIMARY KEY,
  id_condominio INT NOT NULL,
  tipo ENUM('ENTRADA','SAIDA') NOT NULL,
  origem VARCHAR(80) NOT NULL,
  descricao VARCHAR(180) NOT NULL,
  valor DECIMAL(12,2) NOT NULL,
  data_movimentacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mov_condominio FOREIGN KEY (id_condominio) REFERENCES condominios(id_condominio),
  INDEX idx_mov_condominio_data (id_condominio, data_movimentacao)
) ENGINE=InnoDB;
