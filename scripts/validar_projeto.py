#!/usr/bin/env python3
"""Static project checks. Does not replace MySQL/Maven integration tests."""
from pathlib import Path
import re, subprocess, sys, xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
errors = []
required = [
 "database/01_schema.sql", "database/02_objects.sql", "database/03_seed.sql",
 "database/04_security.sql", "backend/pom.xml",
 "backend/src/main/java/br/edu/ucb/condofacil/ApiController.java",
 "backend/src/main/resources/static/index.html",
 "backend/src/main/resources/application.properties",
 "docs/ARTIGO_ACADEMICO.md", "docs/DER.mmd",
]
for name in required:
    if not (ROOT/name).is_file(): errors.append(f"Arquivo ausente: {name}")

try:
    ET.parse(ROOT/"backend/pom.xml")
except Exception as e: errors.append(f"pom.xml inválido: {e}")

html=(ROOT/"backend/src/main/resources/static/index.html").read_text(encoding="utf-8")
scripts=re.findall(r"<script>(.*?)</script>", html, re.S)
if not scripts: errors.append("Nenhum bloco JavaScript encontrado")
else:
    js=ROOT/"scripts"/"_frontend_check.js"
    js.write_text("\\n".join(scripts),encoding="utf-8")
    p=subprocess.run(["node","--check",str(js)],capture_output=True,text=True)
    if p.returncode: errors.append("JavaScript inválido: "+p.stderr.strip())
    js.unlink(missing_ok=True)

java=(ROOT/"backend/src/main/java/br/edu/ucb/condofacil/ApiController.java").read_text(encoding="utf-8")
for route in ["/dashboard","/moradores","/unidades","/cobrancas","/financeiro","/cobrancas-pendentes","/pagamentos","/health"]:
    if route not in java: errors.append(f"Rota esperada não encontrada: {route}")

sql="\\n".join((ROOT/"database"/n).read_text(encoding="utf-8") for n in ["01_schema.sql","02_objects.sql","03_seed.sql","04_security.sql"])
for obj in ["grupos_usuarios","usuarios","fn_gerar_id","fn_calcular_multa","fn_calcular_saldo",
            "trg_validar_pagamento","trg_pos_pagamento","trg_pos_despesa",
            "sp_registrar_pagamento","sp_gerar_cobrancas",
            "vw_cobrancas_pendentes","vw_resumo_financeiro"]:
    if obj not in sql: errors.append(f"Objeto SQL ausente: {obj}")

props=(ROOT/"backend/src/main/resources/application.properties").read_text(encoding="utf-8")
if "username=root" in props.lower(): errors.append("A aplicação está configurada para usar root")
if "condofacil_app" not in props: errors.append("Usuário técnico da aplicação não configurado")

if errors:
    print("FALHAS:")
    print("\\n".join("- "+e for e in errors))
    sys.exit(1)
print("OK: verificações estáticas concluídas.")
print("ATENÇÃO: execute os testes MySQL/Maven descritos em docs/REVISAO_TECNICA.md.")
