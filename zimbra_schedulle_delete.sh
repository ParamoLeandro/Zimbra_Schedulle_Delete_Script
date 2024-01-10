#!/bin/bash

# Obtener la lista de todas las cuentas de usuario en Zimbra
USERS=$(zmprov -l gaa)

# Iterar a través de cada usuario
for USER_EMAIL in $USERS; do
  # Resto del script aquí (usando $USER_EMAIL como la cuenta actual)

  # Variables de configuración específicas del usuario
  SEARCH_SUBJECT="360"
  SEARCH_METADATA="360"

  # Obtener el ID del buzón
  MAILBOX_ID=$(zmprov getMailboxInfo $USER_EMAIL | grep "mailboxId" | awk '{print $2}')

  # Obtener el ID del grupo mbox
  MBOXGROUP_ID=$(expr $MAILBOX_ID % 100)

  # Ejecutar la consulta SQL y guardar el resultado en la variable QUERY_RESULT
  QUERY_RESULT=$(mysql -e "use mboxgroup$MBOXGROUP_ID; select CONCAT(id, '-', mod_content) as itemId from mail_item where mailbox_id = $MAILBOX_ID and subject like '%$SEARCH_SUBJECT%' and metadata like '%$SEARCH_METADATA%';")

  # Verificar si se encontró algún ítem para eliminar
  if [ -n "$QUERY_RESULT" ]; then
    # Imprimir los ID de los ítems a eliminar
    echo "Los ID de los ítems a eliminar para el usuario $USER_EMAIL son:"
    echo "$QUERY_RESULT"

    # Iterar a través de los ID y ejecutar los comandos de zmmailbox
    IFS=$'\n'  # Cambiar el separador de campos interno para manejar líneas
    for ITEM_ID in $QUERY_RESULT; do
      echo "Eliminando ítem con ID: $ITEM_ID para el usuario $USER_EMAIL"
      zmmailbox -z -m $USER_EMAIL deleteItem "$ITEM_ID" > /dev/null 2>&1
    done

    # Verificar si el proceso fue exitoso
    if [ $? -eq 0 ]; then
      echo "Éxito: Los ítems fueron eliminados exitosamente para el usuario $USER_EMAIL."
    else
      echo "Error: Hubo un problema al eliminar los ítems para el usuario $USER_EMAIL."
    fi
  else
    echo "No se encontraron ítems para eliminar para el usuario $USER_EMAIL."
  fi
done
