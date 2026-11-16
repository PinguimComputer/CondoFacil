package br.edu.ucb.condofacil;

import java.math.BigDecimal;
import java.util.*;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

@RestController
@RequestMapping("/api")
@CrossOrigin
public class ApiController {
  private final JdbcTemplate db;
  public ApiController(JdbcTemplate db) { this.db = db; }

  @GetMapping("/health") public Map<String,Object> health() {
    return Map.of("status","ok","database",db.queryForObject("SELECT DATABASE()",String.class));
  }
  @GetMapping("/dashboard") public Map<String,Object> dashboard() {
    Map<String,Object> result=new LinkedHashMap<>();
    result.put("moradores",db.queryForObject("SELECT COUNT(*) FROM moradores WHERE ativo=1",Integer.class));
    result.put("unidades",db.queryForObject("SELECT COUNT(*) FROM unidades",Integer.class));
    result.put("pendentes",db.queryForObject("SELECT COUNT(*) FROM cobrancas WHERE status IN ('PENDENTE','PARCIAL')",Integer.class));
    result.put("financeiro",db.queryForList("SELECT * FROM vw_resumo_financeiro"));
    return result;
  }
  @GetMapping("/moradores") public List<Map<String,Object>> moradores() {
    return db.queryForList("SELECT m.id_morador,m.nome,m.cpf,m.email,m.telefone,m.ativo,u.bloco,u.numero FROM moradores m LEFT JOIN moradias h ON h.id_morador=m.id_morador AND h.data_fim IS NULL LEFT JOIN unidades u ON u.id_unidade=h.id_unidade ORDER BY m.nome");
  }
  @PostMapping("/moradores") @Transactional
  public ResponseEntity<?> criarMorador(@RequestBody Map<String,Object> p) {
    try {
      String cpf=req(p,"cpf").replaceAll("\\D","");
      if (!cpf.matches("\\d{11}")) throw new IllegalArgumentException("CPF deve conter 11 números");
      db.update("INSERT INTO moradores(nome,cpf,email,telefone) VALUES(?,?,?,?)",
        req(p,"nome").trim(),cpf,p.get("email"),p.get("telefone"));
      Integer idMorador=db.queryForObject("SELECT LAST_INSERT_ID()",Integer.class);
      Object unidade=p.get("id_unidade");
      if (unidade!=null && !unidade.toString().isBlank()) {
        db.update("INSERT INTO moradias(id_morador,id_unidade,tipo_vinculo,data_inicio) VALUES(?,?,?,CURRENT_DATE)",
          idMorador,Integer.parseInt(unidade.toString()),"PROPRIETARIO");
      }
      return ResponseEntity.status(201).body(Map.of("mensagem","Morador cadastrado","id_morador",idMorador));
    } catch(Exception e) { TransactionAspectSupport.currentTransactionStatus().setRollbackOnly(); return erro(e); }
  }
  @PutMapping("/moradores/{id}") public ResponseEntity<?> atualizarMorador(@PathVariable int id,@RequestBody Map<String,Object> p) {
    try {
      int n=db.update("UPDATE moradores SET nome=?,cpf=?,email=?,telefone=?,ativo=? WHERE id_morador=?",
        req(p,"nome"),req(p,"cpf"),p.get("email"),p.get("telefone"),p.getOrDefault("ativo",true),id);
      return n==0?ResponseEntity.notFound().build():ResponseEntity.ok(Map.of("mensagem","Morador atualizado"));
    } catch(Exception e) { return erro(e); }
  }
  @DeleteMapping("/moradores/{id}") public ResponseEntity<?> excluirMorador(@PathVariable int id) {
    try {
      int n=db.update("UPDATE moradores SET ativo=0 WHERE id_morador=?",id);
      return n==0?ResponseEntity.notFound().build():ResponseEntity.ok(Map.of("mensagem","Morador inativado"));
    } catch(Exception e) { return erro(e); }
  }
  @GetMapping("/unidades") public List<Map<String,Object>> unidades() {
    return db.queryForList("SELECT u.id_unidade,c.nome AS condominio,u.bloco,u.numero,u.tipo FROM unidades u JOIN condominios c ON c.id_condominio=u.id_condominio ORDER BY u.bloco,u.numero");
  }
  @PostMapping("/unidades") public ResponseEntity<?> criarUnidade(@RequestBody Map<String,Object> p) {
    try {
      db.update("INSERT INTO unidades(id_condominio,bloco,numero,tipo) VALUES(?,?,?,?)",
        Integer.parseInt(req(p,"id_condominio")),req(p,"bloco"),req(p,"numero"),p.getOrDefault("tipo","APARTAMENTO"));
      return ResponseEntity.status(201).body(Map.of("mensagem","Unidade cadastrada"));
    } catch(Exception e) { return erro(e); }
  }
  @GetMapping("/cobrancas") public List<Map<String,Object>> cobrancas() {
    return db.queryForList("SELECT c.id_cobranca,c.descricao,c.valor,c.multa,c.vencimento,c.status,u.bloco,u.numero,fn_calcular_saldo(c.id_cobranca) saldo FROM cobrancas c JOIN unidades u ON u.id_unidade=c.id_unidade ORDER BY c.vencimento");
  }
  @PostMapping("/cobrancas") public ResponseEntity<?> criarCobranca(@RequestBody Map<String,Object> p) {
    try {
      db.update("CALL sp_gerar_cobrancas(?,?,?,?)",Integer.parseInt(req(p,"id_unidade")),req(p,"descricao"),new BigDecimal(req(p,"valor")),req(p,"vencimento"));
      return ResponseEntity.status(201).body(Map.of("mensagem","Cobrança gerada"));
    } catch(Exception e) { return erro(e); }
  }
  @GetMapping("/financeiro") public List<Map<String,Object>> financeiro() { return db.queryForList("SELECT * FROM vw_resumo_financeiro"); }
  @GetMapping("/cobrancas-pendentes") public List<Map<String,Object>> pendentes() { return db.queryForList("SELECT * FROM vw_cobrancas_pendentes ORDER BY vencimento"); }
  @PostMapping("/pagamentos") public ResponseEntity<?> pagamento(@RequestBody Map<String,Object> p) {
    try {
      db.update("CALL sp_registrar_pagamento(?,?,?)",Integer.parseInt(req(p,"id_cobranca")),new BigDecimal(req(p,"valor")),req(p,"forma_pagamento"));
      return ResponseEntity.ok(Map.of("mensagem","Pagamento registrado com sucesso"));
    } catch(Exception e) { return erro(e); }
  }
  private String req(Map<String,Object> p,String k) {
    Object v=p.get(k); if(v==null || v.toString().isBlank()) throw new IllegalArgumentException("Campo obrigatório: "+k); return v.toString();
  }
  private ResponseEntity<Map<String,String>> erro(Exception e) {
    return ResponseEntity.badRequest().body(Map.of("erro",e.getMessage()==null?"Erro na operação":e.getMessage()));
  }
}
