#!/bin/bash

# Instalar dependencias necesarias
apt-get install -y lz4 tar openssl

# Descomprimir recovery.img.lz4 si existe
if [ -f recovery.img.lz4 ]; then
    lz4 -f recovery.img.lz4 recovery.img
    mv recovery.img.lz4 recovery.img.lz4-orig
fi

# Extraer imagen base
off=$(grep -ab -o SEANDROIDENFORCE recovery.img | tail -n 1 | cut -d : -f 1)
if [ -n "$off" ]; then
    dd if=recovery.img of=r.img bs=4k count="$off" iflag=count_bytes
else
    echo "Error: No se pudo encontrar el marcador SEANDROIDENFORCE"
    exit 1
fi

# Generar clave RSA si no existe
if [ ! -f phh.pem ]; then
    openssl genrsa -f4 -out phh.pem 4096
fi

# Crear directorio de trabajo
mkdir -p unpack
cd unpack

# Desempaquetar y modificar ramdisk
../magiskboot unpack ../r.img
../magiskboot cpio ramdisk.cpio extract
cp prop.default ../prop.default

# Aplicar parches binarios
../magiskboot hexpatch system/bin/recovery e10313aaf40300aa6ecc009420010034 e10313aaf40300aa6ecc0094
../magiskboot hexpatch system/bin/recovery eec3009420010034 eec3009420010035
../magiskboot hexpatch system/bin/recovery 3ad3009420010034 3ad3009420010035
../magiskboot hexpatch system/bin/recovery 50c0009420010034 50c0009420010035
../magiskboot hexpatch system/bin/recovery 080109aae80000b4 080109aae80000b5
../magiskboot hexpatch system/bin/recovery 20f0a6ef38b1681c 20f0a6ef38b9681c
../magiskboot hexpatch system/bin/recovery 23f03aed38b1681c 23f03aed38b9681c
../magiskboot hexpatch system/bin/recovery 20f09eef38b1681c 20f09eef38b9681c
../magiskboot hexpatch system/bin/recovery 26f0ceec30b1681c 26f0ceec30b9681c
../magiskboot hexpatch system/bin/recovery 24f0fcee30b1681c 24f0fcee30b9681c
../magiskboot hexpatch system/bin/recovery 27f02eeb30b1681c 27f02eeb30b9681c

# Reagregar archivos al ramdisk
../magiskboot cpio ramdisk.cpio 'add 0755 system/bin/recovery system/bin/recovery'
../magiskboot cpio ramdisk.cpio 'add 0755 prop.default prop.default'

# Reempaquetar imagen
../magiskboot repack ../r.img new-boot.img
cp new-boot.img ../recovery-patched.img
cd ..

# Comprimir y empaquetar archivos finales
if [ -f recovery-patched.img ]; then
    mv recovery-patched.img recovery.img
    lz4 -B6 --content-size recovery.img recovery.img.lz4
    tar cvf patched-recovery.tar recovery.img.lz4 vbmeta.img.lz4
    md5sum -t patched-recovery.tar >> patched-recovery.tar
    mv patched-recovery.tar patched-recovery.tar.md5
fi

# Limpiar archivos temporales
rm -f r.img recovery.img recovery.img.lz4 phh.pem prop.default
rm -rf unpack
