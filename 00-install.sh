#!/bin/bash

# https://github.com/greenbone/gvm-libs/releases
export GVM_LIBS="22.28.1"

# https://github.com/greenbone/gvmd/releases
export GVMD="26.3.0"

# https://github.com/greenbone/pg-gvm/releases
export PG_GVM="22.6.11"

# https://github.com/greenbone/gsa/releases
export GSA="26.0.0"

# https://github.com/greenbone/gsad/releases
export GSAD="24.5.4"

# https://github.com/greenbone/openvas-smb/releases
export OPENVAS_SMB="22.5.10"

# https://github.com/greenbone/openvas-scanner/releases
export OPENVAS_SCANNER="23.28.0"

# https://github.com/greenbone/ospd-openvas/releases
export OSPD_OPENVAS="22.9.0"

# https://github.com/greenbone/notus-scanner/releases
export NOTUS_SCANNER="22.7.2"


echo "Compilando gvm-libs versão $GVM_LIBS..."
# sudo GVM_LIBS="$GVM_LIBS" ./06-build_gvm_libs.sh

echo "Compilando build_gvmd versão $GVMD..."
# sudo GVMD="$GVMD" ./07-build_gvmd.sh

echo "Compilando build_gvmd versão $PG_GVM..."
# sudo PG_GVM="$PG_GVM" ./08-build_pg-gvm.sh

echo "Compilando GSA versão $GSA..."
# sudo GSA="$GSA" ./09-build_gsa.sh

echo "Compilando GSAD versão $GSAD..."
# sudo GSAD="$GSAD" ./10-build_gsad.sh

echo "Compilando OPENVAS_SMB versão $OPENVAS_SMB..."
echo "Compilando OPENVAS_SCANNER versão $OPENVAS_SCANNER..."
# sudo OPENVAS_SMB="$OPENVAS_SMB" OPENVAS_SCANNER="$OPENVAS_SCANNER" ./11-build_scanners.sh

echo "Compilando OSPD_OPENVAS versão $OSPD_OPENVAS..."
# sudo OSPD_OPENVAS="$OSPD_OPENVAS" ./12-build_ospd-openvas.sh

echo "Compilando NOTUS_SCANNER versão $NOTUS_SCANNER..."
sudo NOTUS_SCANNER="$NOTUS_SCANNER" ./13-build_notus-scanner.sh





