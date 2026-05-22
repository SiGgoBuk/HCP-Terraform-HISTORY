resource "tls_private_key" "history_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "history_aws_key" {
  key_name   = "history"
  public_key = tls_private_key.history_key.public_key_openssh
}

resource "local_file" "history_private_key" {
  content  = tls_private_key.history_key.private_key_pem
  filename = "history.pem"
}
