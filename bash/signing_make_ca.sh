#!/usr/bin/env bash
#
# make-test-ca.sh
# -----------------------------------------------------------------------------
# Creates a NAME-CONSTRAINED private Root CA for INTERNAL TEST USE and issues:
#     * one code-signing leaf  (Windows Authenticode + optional Linux)
#     * one TLS leaf for the wildcard you configure (default *.test.local)
#
# The root is deliberately RSA (not ECDSA) for the broadest code-signing
# compatibility with older operating systems, and carries DNS name constraints
# so it can ONLY ever issue TLS certs for the domains you list below.
#
#          >>> FOR TEST FLEETS ONLY -- do not deploy to production. <<<
# -----------------------------------------------------------------------------

set -euo pipefail

# =============================================================================
# CONFIG  -- edit this block
# =============================================================================

# Password that protects EVERY private key this script emits (root + leaves)
# and every .pfx bundle. CHANGE THIS before running.
CA_KEY_PASSWORD="CHANGE-ME-please-use-a-real-passphrase"

# DNS name constraints. This CA is PERMITTED to issue TLS certificates ONLY for
# these names. A leading dot means "subdomains of":
#     "localhost"    -> localhost (and *.localhost)
#     ".local"       -> any *.local
#     ".test.local"  -> any *.test.local
# Anything outside this list will FAIL to validate even though the root is trusted.
PERMITTED_DNS=("localhost" ".local" ".test.local")

# The wildcard the example TLS leaf is issued for (must fall inside PERMITTED_DNS).
TLS_WILDCARD="*.test.local"

# Output directory.
OUT_DIR="./test-ca-out"

# Subject names.
ROOT_SUBJECT="/O=Acme Test/OU=Internal Test PKI/CN=Acme Internal TEST Root CA"
CODESIGN_SUBJECT="/O=Acme Test/CN=Acme TEST Code Signing"
TLS_SUBJECT="/O=Acme Test/CN=${TLS_WILDCARD}"

# --- Cryptography ------------------------------------------------------------
# Root key = RSA-4096 ON PURPOSE:
#   ECDSA is stronger per bit, but older Authenticode verifiers can reject
#   ECDSA-signed code. RSA-4096 is the strongest RSA size that still enjoys
#   universal old-OS support for BOTH code signing and TLS. SHA-256 is the
#   broadest-compatible modern digest for Authenticode.
ROOT_KEY_BITS=4096
LEAF_KEY_BITS=3072          # drop to 2048 for maximum legacy compatibility
HASH_ALG="sha256"

# --- Validity (days) ---------------------------------------------------------
# Locally-trusted private roots are exempt from the public 47-day TLS shrink,
# so long test lifetimes are fine.
ROOT_DAYS=3650              # ~10 years
LEAF_DAYS=825               # ~27 months

# --- Linux code signing ------------------------------------------------------
# When true, also emit the code-signing leaf as DER for the Linux kernel's
# scripts/sign-file and IMA. The codeSigning EKU used here is exactly what the
# kernel keyring checks when EKU enforcement is on.
ENABLE_LINUX_CODE_SIGNING=true

# --- PFX compatibility -------------------------------------------------------
# true  = legacy 3DES/SHA1 .pfx so very old Windows/macOS can import (weaker).
# false = modern AES-256 .pfx (default; fine for current signtool/Windows).
PFX_MAX_COMPAT=false

# =============================================================================
# END CONFIG
# =============================================================================

export CAPASS="$CA_KEY_PASSWORD"

log(){  printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn(){ printf '\n\033[1;33m[!]\033[0m %s\n' "$*" >&2; }

if [ "$CA_KEY_PASSWORD" = "CHANGE-ME-please-use-a-real-passphrase" ]; then
  warn "Using the default CA password. Edit CA_KEY_PASSWORD before any real use."
fi

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# Build the nameConstraints "permitted" line from PERMITTED_DNS.
NC_LINE="critical"
for d in "${PERMITTED_DNS[@]}"; do
  NC_LINE="${NC_LINE},permitted;DNS:${d}"
done

# PFX encoding options.
PFX_OPTS=()
if [ "$PFX_MAX_COMPAT" = "true" ]; then
  PFX_OPTS=(-legacy -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1)
fi

# Helper: generate a password-protected RSA private key.
gen_key(){ # $1 bits  $2 outfile
  openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:$1" \
    -aes256 -pass env:CAPASS -out "$2"
}

# Helper: sign a CSR with the root CA using an extension file.
sign_leaf(){ # $1 csr  $2 extfile  $3 out.crt
  openssl x509 -req -in "$1" \
    -CA "root-ca-PUBLIC.crt" -CAkey "root-ca-PRIVATE-KEY-ENCRYPTED.pem" \
    -passin env:CAPASS -CAcreateserial \
    "-${HASH_ALG}" -days "${LEAF_DAYS}" \
    -extfile "$2" -out "$3"
}

# -----------------------------------------------------------------------------
# 1) ROOT CA
# -----------------------------------------------------------------------------
log "Generating encrypted ROOT CA private key (RSA-${ROOT_KEY_BITS})"
gen_key "${ROOT_KEY_BITS}" "root-ca-PRIVATE-KEY-ENCRYPTED.pem"

cat > root.cnf <<EOF
[req]
distinguished_name = dn
prompt = no
[dn]
[v3_ca]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
nameConstraints = ${NC_LINE}
EOF

log "Creating self-signed, name-constrained ROOT CA certificate"
openssl req -x509 -new \
  -key "root-ca-PRIVATE-KEY-ENCRYPTED.pem" -passin env:CAPASS \
  "-${HASH_ALG}" -days "${ROOT_DAYS}" \
  -subj "${ROOT_SUBJECT}" \
  -config root.cnf -extensions v3_ca \
  -out "root-ca-PUBLIC.crt"

# -----------------------------------------------------------------------------
# 2) CODE-SIGNING LEAF
# -----------------------------------------------------------------------------
log "Generating CODE-SIGNING leaf (RSA-${LEAF_KEY_BITS})"
gen_key "${LEAF_KEY_BITS}" "codesign-PRIVATE-KEY-ENCRYPTED.pem"
openssl req -new -key "codesign-PRIVATE-KEY-ENCRYPTED.pem" -passin env:CAPASS \
  -subj "${CODESIGN_SUBJECT}" -out codesign.csr

# EKU codeSigning, left non-critical for the widest verifier compatibility.
cat > codesign.ext <<'EOF'
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
sign_leaf codesign.csr codesign.ext "codesign-PUBLIC.crt"

log "Bundling code-signing key+cert+chain into .pfx for signtool"
openssl pkcs12 -export -out "codesign-BUNDLE.pfx" \
  -inkey "codesign-PRIVATE-KEY-ENCRYPTED.pem" -passin env:CAPASS \
  -in "codesign-PUBLIC.crt" -certfile "root-ca-PUBLIC.crt" \
  -passout env:CAPASS "${PFX_OPTS[@]}"

if [ "$ENABLE_LINUX_CODE_SIGNING" = "true" ]; then
  log "Emitting Linux (DER) form of the code-signing certificate"
  openssl x509 -in "codesign-PUBLIC.crt" -outform DER -out "codesign-linux.der"
fi

# -----------------------------------------------------------------------------
# 3) TLS LEAF
# -----------------------------------------------------------------------------
log "Generating TLS leaf for ${TLS_WILDCARD} (RSA-${LEAF_KEY_BITS})"
gen_key "${LEAF_KEY_BITS}" "tls-wildcard.test.local-PRIVATE-KEY-ENCRYPTED.pem"
openssl req -new -key "tls-wildcard.test.local-PRIVATE-KEY-ENCRYPTED.pem" \
  -passin env:CAPASS -subj "${TLS_SUBJECT}" -out tls.csr

cat > tls.ext <<EOF
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:${TLS_WILDCARD}
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
sign_leaf tls.csr tls.ext "tls-wildcard.test.local-PUBLIC.crt"

log "Bundling TLS key+cert+chain into .pfx"
openssl pkcs12 -export -out "tls-wildcard.test.local-BUNDLE.pfx" \
  -inkey "tls-wildcard.test.local-PRIVATE-KEY-ENCRYPTED.pem" -passin env:CAPASS \
  -in "tls-wildcard.test.local-PUBLIC.crt" -certfile "root-ca-PUBLIC.crt" \
  -passout env:CAPASS "${PFX_OPTS[@]}"

# -----------------------------------------------------------------------------
# 4) VERIFY + SUMMARY
# -----------------------------------------------------------------------------
log "Verifying both leaves chain to the root and satisfy name constraints"
openssl verify -CAfile "root-ca-PUBLIC.crt" "codesign-PUBLIC.crt"
openssl verify -CAfile "root-ca-PUBLIC.crt" "tls-wildcard.test.local-PUBLIC.crt"

# Remove intermediates.
rm -f codesign.csr tls.csr root.cnf codesign.ext tls.ext root-ca-PUBLIC.srl

log "Done. Files in ${OUT_DIR}:"
LINUX_LINE=""
[ "$ENABLE_LINUX_CODE_SIGNING" = "true" ] && \
  LINUX_LINE="  codesign-linux.der                         DER code-signing cert for Linux sign-file / IMA"

cat <<EOF

  PUBLIC  -- safe to distribute to test machines
  ----------------------------------------------------------------------------
  root-ca-PUBLIC.crt                         import into Trusted Root CA store
  codesign-PUBLIC.crt                        the code-signing certificate
  tls-wildcard.test.local-PUBLIC.crt         the TLS server certificate
${LINUX_LINE}

  SECRET  -- keep OFF test machines; all protected by your password
  ----------------------------------------------------------------------------
  root-ca-PRIVATE-KEY-ENCRYPTED.pem          ROOT private key (guard this most)
  codesign-PRIVATE-KEY-ENCRYPTED.pem         code-signing private key
  tls-wildcard.test.local-PRIVATE-KEY-ENCRYPTED.pem   TLS private key
  codesign-BUNDLE.pfx                        code-signing key+cert+chain
  tls-wildcard.test.local-BUNDLE.pfx         TLS key+cert+chain

  USAGE
  ----------------------------------------------------------------------------
  Windows Authenticode:
    signtool sign /f codesign-BUNDLE.pfx /p '<password>' /fd sha256 \\
      /tr http://timestamp.digicert.com /td sha256 yourapp.exe

  Linux kernel module (if enabled): sign-file wants the UNENCRYPTED key, so
  decrypt once first:
    openssl rsa -in codesign-PRIVATE-KEY-ENCRYPTED.pem -out codesign.key
    scripts/sign-file sha256 codesign.key codesign-linux.der module.ko

  TLS server: point it at tls-wildcard.test.local-PUBLIC.crt + its key
  (config depends on the server; most accept an encrypted key with a passphrase
  prompt, or extract from the .pfx). Import root-ca-PUBLIC.crt into client trust.
EOF
