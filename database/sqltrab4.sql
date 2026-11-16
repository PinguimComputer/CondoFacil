CREATE USER IF NOT EXISTS 'condofacil_app'@'localhost'
  IDENTIFIED BY '123';
CREATE USER IF NOT EXISTS 'condofacil_app'@'127.0.0.1'
  IDENTIFIED BY '123';
ALTER USER 'condofacil_app'@'localhost' IDENTIFIED BY '123';
ALTER USER 'condofacil_app'@'127.0.0.1' IDENTIFIED BY '123';

GRANT SELECT, INSERT, UPDATE ON condofacil.moradores TO 'condofacil_app'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condofacil.moradores TO 'condofacil_app'@'127.0.0.1';
GRANT SELECT, INSERT ON condofacil.moradias TO 'condofacil_app'@'localhost';
GRANT SELECT, INSERT ON condofacil.moradias TO 'condofacil_app'@'127.0.0.1';
GRANT SELECT, INSERT ON condofacil.unidades TO 'condofacil_app'@'localhost';
GRANT SELECT, INSERT ON condofacil.unidades TO 'condofacil_app'@'127.0.0.1';
GRANT SELECT ON condofacil.condominios TO 'condofacil_app'@'localhost';
GRANT SELECT ON condofacil.condominios TO 'condofacil_app'@'127.0.0.1';
GRANT SELECT ON condofacil.cobrancas TO 'condofacil_app'@'localhost';
GRANT SELECT ON condofacil.cobrancas TO 'condofacil_app'@'127.0.0.1';
GRANT SELECT ON condofacil.vw_resumo_financeiro TO 'condofacil_app'@'localhost';
GRANT SELECT ON condofacil.vw_resumo_financeiro TO 'condofacil_app'@'127.0.0.1';
GRANT SELECT ON condofacil.vw_cobrancas_pendentes TO 'condofacil_app'@'localhost';
GRANT SELECT ON condofacil.vw_cobrancas_pendentes TO 'condofacil_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE condofacil.sp_registrar_pagamento TO 'condofacil_app'@'localhost';
GRANT EXECUTE ON PROCEDURE condofacil.sp_registrar_pagamento TO 'condofacil_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE condofacil.sp_gerar_cobrancas TO 'condofacil_app'@'localhost';
GRANT EXECUTE ON PROCEDURE condofacil.sp_gerar_cobrancas TO 'condofacil_app'@'127.0.0.1';
FLUSH PRIVILEGES;
