#!/usr/bin/expect -f

set name [lindex $argv 0]
set csr_path "/root/tests_step/csr/$name.csr"
set crt_path "/root/tests_step/certificates/$name.crt"
set ca_cert "/root/step/certs/intermediate_ca.crt"
set ca_key "/root/step/secrets/intermediate_ca_key"

puts "Signing CSR for $name with CSR file: $csr_path"
puts "CA Cert: $ca_cert"
puts "CA Key: $ca_key"
puts "Output Cert: $crt_path"

spawn step certificate sign $csr_path $ca_cert $ca_key
expect {
    "Please enter the password to decrypt" {
        send -- "iFN5VwWVvy4ezEWByu6CPVma8AsCotUUMsUHF9vr\r"
        exp_continue
    }
    eof
}

# Capture the certificate output
set output $expect_out(buffer)

# Save the certificate to the desired path
set fileId [open $crt_path "w"]
puts $fileId $output
close $fileId

if { [file exists $crt_path] } {
    puts "Certificate successfully generated at $crt_path"
} else {
    puts "Failed to generate certificate"
    exit 1
}
