# --------------------------------------------------
# Generate SSH Keypair
# --------------------------------------------------
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "${path.module}/../pavan-624615_api_key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "kp" {
  key_name   = "${var.project_prefix}-${var.env}-kp"
  public_key = tls_private_key.key.public_key_openssh
}

# --------------------------------------------------
# Security Group for API EC2
# --------------------------------------------------
resource "aws_security_group" "api_sg" {
  name   = "${var.project_prefix}-${var.env}-api-sg"
  vpc_id = var.vpc_id

  # Allow SSH from your CIDR
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr] # ← dynamic SSH CIDR
  }

  # Allow API port 8080 publicly
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-api-sg"
  }
}

# --------------------------------------------------
# EC2 Instance for SmartLogiX API
# --------------------------------------------------
resource "aws_instance" "api" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.api_instance_type
  subnet_id              = var.public_subnet_id
  key_name               = aws_key_pair.kp.key_name
  iam_instance_profile   = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  vpc_security_group_ids = [aws_security_group.api_sg.id]

  # Pass DB values into user_data.tpl
  user_data = templatefile("${path.module}/user_data.tpl", {
    db_endpoint    = var.db_endpoint,
    db_username    = var.db_username,
    db_password    = var.db_password,
    project_prefix = var.project_prefix,
    ROWS           = 0,
    CWA_DEB_URL    = var.CWA_DEB_URL
  })

  tags = {
    Name = "${var.project_prefix}-${var.env}-api"
  }
}

# --------------------------------------------------
# Ubuntu AMI Lookup
# --------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
