================================================================
  Imágenes Docker - Intranet Escolar con Nextcloud
  Exportación para uso offline
================================================================

CONTENIDO
---------
Este directorio contiene las imágenes Docker necesarias para
ejecutar el proyecto sin conexión a Internet.

Imágenes incluidas:
  - mariadb:11
  - nextcloud:29-apache
  - louislam/uptime-kuma:1

IMPORTACIÓN
-----------
Para cargar estas imágenes en otro equipo:

1. Copia este directorio completo al equipo destino
2. Ejecuta el script de importación:
   
   bash import.sh

3. Verifica que las imágenes se han cargado:
   
   docker images

ALTERNATIVA MANUAL
------------------
Puedes cargar las imágenes manualmente:

   docker load -i mariadb_11.tar
   docker load -i nextcloud_29-apache.tar
   docker load -i louislam_uptime-kuma_1.tar

SIGUIENTE PASO
--------------
Una vez importadas las imágenes, puedes clonar o copiar el
repositorio del proyecto y ejecutar:

   bash scripts/init.sh

================================================================
