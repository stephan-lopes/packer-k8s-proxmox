# !IMPORTANT
# Esse é um script destinado a realizar a criação de uma imagem personalizada, a cada vez que executa o packer, sem ficar com imagens repetidas dentro do proxmox.

# Variáveis de Ambiente Auxiliares
STATUS="null"

# Função destinada a realização das checagens de Status da Tarefa em andamento. Ele trava o processo até validar que a tarefa está encerrada, e prosseguir com a próxima tarefa.
function check() {
 while [[ $STATUS != "OK" ]]; do
     STATUS=$(curl -sk -X GET -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" "$PROXMOX_URL/nodes/$NODE/tasks/$1/status" | jq -r .data.exitstatus)
 done
 sleep 2
 STATUS=""
}

echo "Template Name $TEMPLATE_NAME"

# Parte 1: Coleta de ID da Imagem Recém Criada
# Descrição: Nessa parte, existe uma coleta simples do id, para utilização posterior no código.
echo "Iniciando script..."
SOURCE_VMID=$(curl -sk -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" "$PROXMOX_URL/cluster/resources?type=vm" | jq -r ".data[] | select( .name == \"$TEMPLATE_NAME\").vmid")
sleep 2

# Parte 2: Remoção de Imagem Latest para Substituição de Imagem
# Descrição: Remove a Imagem Latest, caso já tenha sido criada
echo "Deletando a imagem mais recente [$VMID]..."
if [[ $(curl -sk -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" "$PROXMOX_URL/cluster/resources?type=vm" | jq -r ".data[].vmid"| grep $VMID ) ]]; then
    delete_response=$(curl -sk -X DELETE -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" "$PROXMOX_URL/nodes/$NODE/qemu/$VMID" | jq -r .data ) && check $delete_response
fi


# Parte 3: Clonagem da Imagem Recém Criada para o ID da Imagem Latest
echo "Clonando a imagem criada: From [$SOURCE_VMID] To [$VMID]..."
clone_response=$(curl -sk -X POST -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" -d "newid=$VMID&name=${TEMPLATE_NAME}-latest&full=1" "$PROXMOX_URL/nodes/$NODE/qemu/$SOURCE_VMID/clone" | jq -r .data ) && check $clone_response

# Parte 4: Transformação da Imagem Clonada em Template
echo "Convertendo a imagem $VMID em um template..."
template_response=$(curl -sk -X POST -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" "$PROXMOX_URL/nodes/proxmox/qemu/$VMID/template" | jq -r .data ) && check $template_response 

# Parte 5: Deleta Template Criado pelo Packer
echo "Removendo Template Criado pelo Packer"
remove_response=$(curl -sk -X DELETE -H "Authorization: PVEAPIToken=$PROXMOX_USERNAME=$PROXMOX_TOKEN" "$PROXMOX_URL/nodes/$NODE/qemu/$SOURCE_VMID" | jq -r .data ) && check $remove_response