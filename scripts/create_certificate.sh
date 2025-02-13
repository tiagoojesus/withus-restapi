#!/usr/bin/expect -f

set certificate_name [lindex $argv 0];

# Definir as variáveis
set timeout -1
#set command "step certificate create $certificate_name /root/tests_step/certificates/$certificate_name.crt /root/tests_step/keys/$certificate_name.key --ca /root/step/certs/intermediate_ca.crt --ca-key /root/step/secrets/intermediate_ca_key"
set password "iFN5VwWVvy4ezEWByu6CPVma8AsCotUUMsUHF9vr"

# Iniciar a sessão SSH e executar o comando
#spawn ssh $user@$host -o StrictHostKeyChecking=no -t $command
spawn step certificate create $certificate_name /root/tests_step/certificates/$certificate_name.crt /root/tests_step/keys/$certificate_name.key --ca /root/step/certs/intermediate_ca.crt --ca-key /root/step/secrets/intermediate_ca_key

# Esperar e responder às perguntas interativas
expect "Please enter the password to decrypt /root/step/secrets/intermediate_ca_key:"
send "$password\r"
expect "Please enter the password to encrypt the private key:"
send "$password\r"
expect "Would you like to overwrite /root/tests_step/keys/*?.key *?y/n*?:"
send "y\r"
expect "Would you like to overwrite /root/tests_step/certificates/*?.crt *?y/n*?:"
send "y\r"

# Esperar pelo fim da execução do comando
expect eof







#!/usr/bin/expect -f

set name [lindex $argv 0]
set csr_path "/root/tests_step/csr/$name.csr"
set crt_path "/root/tests_step/certificates/$name.crt"
set password "iFN5VwWVvy4ezEWByu6CPVma8AsCotUUMsUHF9vr"

spawn step ca sign --ca-url https://localhost:9000 --root /root/step/certs/root_ca.crt --key /root/step/secrets/intermediate_ca_key --cert /root/step/certs/intermediate_ca.crt $csr_path $crt_path
expect "Provisioner Key Password:"
send "$password\r"
expect eof

