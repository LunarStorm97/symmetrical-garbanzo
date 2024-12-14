#!/bin/bash

# Instalar dependencias
apt-get install lz4 tar openssl

# Descomprimir recovery.img.lz4 si existe
if [ -f recovery.img.lz4 ]; then
    lz4 -f recovery.img.lz4 recovery.img
fi

# Renombrar el archivo original
if [ -f recovery.img.lz4 ]; then
    mv recovery.img.lz4 recovery.img.lz4-orig
fi

# Obtener el offset de SEANDROIDENFORCE
off=$(grep -ab -o SEANDROIDENFORCE recovery.img | tail -n 1 | cut -d : -f 1)
dd if=recovery.img of=r.img bs=4k count=$off iflag=count_bytes

# Generar clave si no existe
if [ ! -f phh.pem ]; then
    openssl genrsa -f4 -out phh.pem 4096
fi

# Crear directorio para la extracción
mkdir unpack
cd unpack

# Desempaquetar el archivo con magiskboot
../magiskboot unpack ../r.img
../magiskboot cpio ramdisk.cpio extract
cp prop.default ../prop.default

# Realizar parches en el archivo de recuperación
../magiskboot hexpatch system/bin/recovery e10313aaf40300aa6ecc009420010034 e10313aaf40300aa6ecc0094
# (otros parches aquí)
../magiskboot cpio ramdisk.cpio 'add 0755 system/bin/recovery system/bin/recovery'
../magiskboot cpio ramdisk.cpio 'add 0755 prop.default prop.default'

# Volver a empaquetar y mover el nuevo archivo
../magiskboot repack ../r.img new-boot.img
cp new-boot.img ../recovery-patched.img
cd ..

# Limpiar archivos temporales
rm recovery.img
mv recovery-patched.img recovery.img

# Comprimir recovery.img a .lz4
if [ -f recovery.img ]; then
    lz4 -B6 --content-size recovery.img
fi

# Crear el archivo tar con los archivos .lz4
tar cvf patched-recovery.tar recovery.img.lz4 vbmeta.img.lz4

# Generar y guardar la suma MD5 en un archivo separado
if [ -f patched-recovery.tar ]; then
    md5sum patched-recovery.tar > patched-recovery.tar.md5
fi

# Mover el archivo final
mv patched-recovery.tar patched-recovery.tar.md5

# Limpiar archivos temporales
rm r.img
rm -r unpack
rm recovery.img
rm recovery.img.lz4
rm phh.pem
rm prop.default
