USE condofacil;
INSERT INTO condominios(nome,endereco,cnpj) VALUES
('Jardim das Flores','Rua das Acácias, 100 - Brasília/DF','12345678000199');
INSERT INTO unidades(id_condominio,bloco,numero) VALUES
(1,'A','101'),(1,'A','102'),(1,'B','201'),(1,'B','202');
INSERT INTO moradores(nome,cpf,email,telefone) VALUES
('Ana Souza','11111111111','ana@email.com','61999990001'),
('Bruno Lima','22222222222','bruno@email.com','61999990002'),
('Carla Mendes','33333333333','carla@email.com','61999990003');
INSERT INTO moradias(id_morador,id_unidade,tipo_vinculo,data_inicio) VALUES
(1,1,'PROPRIETARIO','2025-01-01'),(2,2,'INQUILINO','2025-03-01'),(3,3,'PROPRIETARIO','2024-06-01');
INSERT INTO funcionarios(id_condominio,nome,cargo,email) VALUES
(1,'Marcos Oliveira','Síndico','marcos@condominio.com');
INSERT INTO grupos_usuarios(nome,descricao) VALUES
('ADMIN','Acesso administrativo'),('SINDICO','Gestão do condomínio'),('MORADOR','Acesso do morador');
INSERT INTO usuarios(id_usuario,nome,email,senha_hash) VALUES
(fn_gerar_id(),'Síndico Demonstração','sindico@condofacil.local','$2a$10$HASH_DE_DEMONSTRACAO_NAO_AUTENTICAVEL');
INSERT INTO usuario_grupo(id_usuario,id_grupo)
SELECT u.id_usuario,g.id_grupo FROM usuarios u JOIN grupos_usuarios g ON g.nome='SINDICO'
WHERE u.email='sindico@condofacil.local';
INSERT INTO cobrancas(id_unidade,descricao,valor,vencimento) VALUES
(1,'Taxa condominial - novembro',650.00,DATE_ADD(CURRENT_DATE,INTERVAL 10 DAY)),
(2,'Taxa condominial - novembro',650.00,DATE_SUB(CURRENT_DATE,INTERVAL 10 DAY)),
(3,'Fundo de reserva',120.00,DATE_ADD(CURRENT_DATE,INTERVAL 15 DAY));
INSERT INTO despesas(id_condominio,descricao,categoria,valor,data_despesa) VALUES
(1,'Manutenção do elevador','MANUTENÇÃO',380.00,CURRENT_DATE);
CALL sp_registrar_pagamento(1,200.00,'PIX');
