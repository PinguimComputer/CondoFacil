# CondoFácil — Sistema de Gerenciamento de Condomínios

Projeto desenvolvido para a disciplina de Banco de Dados da Universidade Católica de Brasília (UCB).

## Objetivo
Facilitar o gerenciamento de condomínios, incluindo moradores, unidades, cobranças, pagamentos e controle financeiro.

## Tecnologias utilizadas
- Java e Spring Boot
- HTML, CSS e JavaScript
- MySQL
- Maven

## Funcionalidades
- Cadastro e consulta de moradores
- Gerenciamento de unidades
- Controle de cobranças e pagamentos
- Consultas financeiras
- Integração com banco de dados MySQL

## Como executar
1. Instale Java 17 ou superior, Maven e MySQL.
2. Execute os arquivos da pasta `database`, na ordem: `sqltrab1.sql`, `sqltrab2.sql`, `sqltrab3.sql` e `sqltrab4.sql`.
3. Configure a conexão com o MySQL no arquivo `backend/src/main/resources/application.properties`, usando as credenciais configuradas no banco.
4. Abra o terminal na pasta `backend`.
5. Execute `mvn spring-boot:run`.
6. Acesse `http://localhost:8081`.

## Estrutura do projeto
- `backend/` — aplicação Java e interface
- `database/` — scripts SQL
- `scripts/` — validação do projeto

## Equipe
Erik Ferreira e Felipe Muniz — Engenharia de Software — UCB — 2026