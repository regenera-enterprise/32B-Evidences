#!/bin/bash
set -euo pipefail
export LC_ALL=C
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PDF="00-PUBLICACAO/Regenera-32B-Dossie-Zenodo-44p.pdf"
EDITION="00-PUBLICACAO/ALLOWED_SIGNERS"
HISTORICA="01-EVIDENCIAS/verification/ALLOWED_SIGNERS"
ID="don-paulo-ricardo-de-leao"
NS="regenera-32b-validation"

shasum -a 256 -c UNIFIED-SHA256.txt
python3 - "$PDF" << 'PY'
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
terms = (b"ChatGPT", b"OpenAI", b"gpt-5", b"c2pa", b"C2PA", b"MuPDF", b"xmpmeta", b"/JavaScript")
found = [t.decode() for t in terms if t in data]
tail = data[data.rfind(b"trailer"):]
if found or b"/Info" in tail or b"/ID" in tail:
    raise SystemExit("PDF com metadado: " + ", ".join(found))
print("PDF METADATA: PASS")
PY
for f in \
  "$PDF" \
  00-PUBLICACAO/REGENERA-ED25519-PUBLIC-KEY.pub \
  00-PUBLICACAO/REGENERA-ED25519-FINGERPRINT.txt \
  00-PUBLICACAO/ALLOWED_SIGNERS \
  README-UNIFICADO.txt \
  06-VERIFICACAO/RELATORIO-UNIFICADO.txt \
  06-VERIFICACAO/VERIFICAR-NO-MAC.sh \
  .gitignore \
  UNIFIED-SHA256.txt
do
  ssh-keygen -Y verify -f "$EDITION" -I "$ID" -n "$NS" -s "$f.sig" < "$f" >/dev/null
done
echo "EDITION SIGNATURES: PASS"
COUNT=0
while IFS= read -r -d '' S; do
  REL="${S#01-EVIDENCIAS/signatures/}"
  ORIG="01-EVIDENCIAS/${REL%.sig}"
  [ -f "$ORIG" ] || { echo "ERRO: original ausente: $ORIG"; exit 1; }
  ssh-keygen -Y verify -f "$HISTORICA" -I "$ID" -n "$NS" -s "$S" < "$ORIG" >/dev/null
  COUNT=$((COUNT+1))
done < <(find 01-EVIDENCIAS/signatures -type f -name '*.sig' -print0 | sort -z)
echo "EVIDENCE SIGNATURES: $COUNT PASS"
echo "REGENERA 32B UNIFIED PACKAGE: PASS"
