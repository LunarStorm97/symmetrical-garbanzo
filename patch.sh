# Instalar dependencias necesarias
apt-get install lz4 tar openssl

# Descomprimir recovery.img.lz4 si existe
if [ -f recovery.img.lz4 ]; then
    lz4 -f recovery.img.lz4 recovery.img
fi

# Renombrar el archivo original si existe
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

# Volver a empaquetar y agregar archivos
../magiskboot cpio ramdisk.cpio 'add 0755 system/bin/recovery system/bin/recovery'
../magiskboot cpio ramdisk.cpio 'add 0755 prop.default prop.default'

# Reempaquetar la imagen de arranque
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
