USE condofacil;
DROP VIEW IF EXISTS vw_cobrancas_pendentes;
DROP VIEW IF EXISTS vw_resumo_financeiro;
DROP PROCEDURE IF EXISTS sp_registrar_pagamento;
DROP PROCEDURE IF EXISTS sp_gerar_cobrancas;
DROP FUNCTION IF EXISTS fn_calcular_saldo;
DROP FUNCTION IF EXISTS fn_calcular_multa;
DROP FUNCTION IF EXISTS fn_gerar_id;
DROP TRIGGER IF EXISTS trg_validar_pagamento;
DROP TRIGGER IF EXISTS trg_pos_pagamento;
DROP TRIGGER IF EXISTS trg_pos_despesa;

DELIMITER $$
CREATE FUNCTION fn_gerar_id() RETURNS CHAR(36)
NOT DETERMINISTIC NO SQL
RETURN UUID()$$

CREATE FUNCTION fn_calcular_saldo(p_id_cobranca INT) RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(12,2);
  DECLARE v_pago DECIMAL(12,2);
  SELECT valor + multa INTO v_total FROM cobrancas WHERE id_cobranca = p_id_cobranca;
  SELECT COALESCE(SUM(valor),0) INTO v_pago FROM pagamentos WHERE id_cobranca = p_id_cobranca;
  RETURN COALESCE(v_total,0) - v_pago;
END$$

CREATE FUNCTION fn_calcular_multa(p_id_cobranca INT) RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
  DECLARE v_valor DECIMAL(12,2);
  DECLARE v_venc DATE;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_valor = NULL, v_venc = NULL;
  SELECT valor, vencimento INTO v_valor, v_venc
    FROM cobrancas WHERE id_cobranca = p_id_cobranca;
  IF v_venc IS NULL OR CURRENT_DATE <= v_venc THEN RETURN 0; END IF;
  RETURN ROUND(v_valor * 0.02 + v_valor * 0.00033 * DATEDIFF(CURRENT_DATE, v_venc), 2);
END$$

CREATE TRIGGER trg_validar_pagamento BEFORE INSERT ON pagamentos
FOR EACH ROW
BEGIN
  -- A procedure valida o saldo sob bloqueio FOR UPDATE.
  -- A trigger mantém uma regra local que também protege inserções administrativas.
  IF NEW.valor <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pagamento deve ser positivo';
  END IF;
END$$

CREATE TRIGGER trg_pos_pagamento AFTER INSERT ON pagamentos
FOR EACH ROW
BEGIN
  DECLARE v_condominio INT;
  -- Não consulta a tabela pagamentos aqui: a linha está sendo inserida nela.
  SELECT u.id_condominio INTO v_condominio
    FROM cobrancas c JOIN unidades u ON u.id_unidade = c.id_unidade
    WHERE c.id_cobranca = NEW.id_cobranca;
  INSERT INTO movimentacoes(id_movimentacao,id_condominio,tipo,origem,descricao,valor)
    VALUES(fn_gerar_id(),v_condominio,'ENTRADA','PAGAMENTO',
      CONCAT('Pagamento da cobrança ',NEW.id_cobranca),NEW.valor);
END$$

CREATE TRIGGER trg_pos_despesa AFTER INSERT ON despesas
FOR EACH ROW
INSERT INTO movimentacoes(id_movimentacao,id_condominio,tipo,origem,descricao,valor)
VALUES(fn_gerar_id(),NEW.id_condominio,'SAIDA','DESPESA',NEW.descricao,NEW.valor)$$

CREATE PROCEDURE sp_registrar_pagamento(
  IN p_id_cobranca INT, IN p_valor DECIMAL(12,2), IN p_forma VARCHAR(20)
)
proc: BEGIN
  DECLARE v_id_bloqueado INT DEFAULT NULL;
  DECLARE v_valor DECIMAL(12,2) DEFAULT 0;
  DECLARE v_vencimento DATE DEFAULT NULL;
  DECLARE v_status VARCHAR(20) DEFAULT NULL;
  DECLARE v_multa DECIMAL(12,2) DEFAULT 0;
  DECLARE v_pago DECIMAL(12,2) DEFAULT 0;
  DECLARE v_saldo DECIMAL(12,2) DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_id_bloqueado = NULL;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_valor IS NULL OR p_valor <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O valor do pagamento deve ser maior que zero';
  END IF;
  IF p_forma IS NULL OR p_forma NOT IN ('PIX','DINHEIRO','BOLETO','TRANSFERENCIA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Forma de pagamento inválida';
  END IF;

  START TRANSACTION;

  -- O bloqueio serializa pagamentos concorrentes da mesma cobrança.
  SELECT id_cobranca, valor, vencimento, status
    INTO v_id_bloqueado, v_valor, v_vencimento, v_status
    FROM cobrancas
    WHERE id_cobranca = p_id_cobranca
    FOR UPDATE;

  IF v_id_bloqueado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cobrança não encontrada';
  END IF;
  IF v_status NOT IN ('PENDENTE','PARCIAL') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta cobrança não aceita novos pagamentos';
  END IF;

  -- Calcula a multa com os dados já bloqueados, sem chamar função que leia
  -- cobrancas dentro do próprio UPDATE dessa tabela.
  IF CURRENT_DATE > v_vencimento THEN
    SET v_multa = ROUND(v_valor * 0.02 +
      v_valor * 0.00033 * DATEDIFF(CURRENT_DATE, v_vencimento), 2);
  ELSE
    SET v_multa = 0;
  END IF;

  UPDATE cobrancas SET multa = v_multa WHERE id_cobranca = p_id_cobranca;

  SELECT COALESCE(SUM(valor), 0) INTO v_pago
    FROM pagamentos WHERE id_cobranca = p_id_cobranca;
  SET v_saldo = v_valor + v_multa - v_pago;

  IF p_valor > v_saldo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pagamento maior que o saldo devedor';
  END IF;

  INSERT INTO pagamentos(id_pagamento, id_cobranca, valor, forma_pagamento)
    VALUES(fn_gerar_id(), p_id_cobranca, p_valor, p_forma);

  UPDATE cobrancas
    SET status = IF(v_saldo - p_valor <= 0, 'PAGA', 'PARCIAL')
    WHERE id_cobranca = p_id_cobranca;

  COMMIT;
END$$

CREATE PROCEDURE sp_gerar_cobrancas(
  IN p_id_unidade INT, IN p_descricao VARCHAR(160),
  IN p_valor DECIMAL(12,2), IN p_vencimento DATE
)
BEGIN
  IF p_valor <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Valor deve ser positivo'; END IF;
  INSERT INTO cobrancas(id_unidade,descricao,valor,vencimento)
  VALUES(p_id_unidade,p_descricao,p_valor,p_vencimento);
END$$
DELIMITER ;

CREATE OR REPLACE VIEW vw_cobrancas_pendentes AS
SELECT c.id_cobranca, c.id_unidade, u.bloco, u.numero, c.descricao,
       c.valor, c.multa, c.vencimento, c.status,
       fn_calcular_saldo(c.id_cobranca) AS saldo
FROM cobrancas c JOIN unidades u ON u.id_unidade=c.id_unidade
WHERE c.status IN ('PENDENTE','PARCIAL');

CREATE OR REPLACE VIEW vw_resumo_financeiro AS
SELECT co.id_condominio, co.nome AS condominio,
  COALESCE(SUM(CASE WHEN m.tipo='ENTRADA' THEN m.valor ELSE 0 END),0) AS total_entradas,
  COALESCE(SUM(CASE WHEN m.tipo='SAIDA' THEN m.valor ELSE 0 END),0) AS total_saidas,
  COALESCE(SUM(CASE WHEN m.tipo='ENTRADA' THEN m.valor ELSE -m.valor END),0) AS saldo
FROM condominios co LEFT JOIN movimentacoes m ON m.id_condominio=co.id_condominio
GROUP BY co.id_condominio, co.nome;
