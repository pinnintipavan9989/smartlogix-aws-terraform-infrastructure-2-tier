resource "aws_db_subnet_group" "this" {
  name       = "${var.project_prefix}-${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project_prefix}-${var.env}-mysql"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = "smartlogix"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "${var.project_prefix}-${var.env}-mysql"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_prefix}-${var.env}-db-sg"
  vpc_id      = var.vpc_id
  description = "Allow DB access from API SG only"

  tags = {
    Name = "${var.project_prefix}-${var.env}-db-sg"
  }
}

resource "aws_security_group_rule" "allow_from_api" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = var.api_security_group_id
}



resource "aws_network_acl" "db_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    action     = "allow"
    cidr_block = "10.0.0.0/16" # adjust to your VPC CIDR
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags = { Name = "${var.project_prefix}-${var.env}-db-acl" }
}
