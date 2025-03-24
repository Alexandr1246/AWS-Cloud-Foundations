provider "aws" {
  region = "us-east-1"
}

# --- Security Group for RDS ---
resource "aws_security_group" "db_sg" {
  name        = "DB Security Group"
  description = "Permit access from Web Security Group"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
}

# --- DB Subnet Group ---
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  description = "DB Subnet Group"
}

# --- RDS MySQL Instance ---
resource "aws_db_instance" "lab_db" {
  identifier           = "lab-db"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username           = "main"
  password           = "lab-password"
  multi_az           = true
  storage_type       = "gp2"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible  = false
  skip_final_snapshot = true
  backup_retention_period = 0
}

# --- Web Server Security Group (для соединения с RDS) ---
resource "aws_security_group" "web_sg" {
  name        = "Web Security Group"
  description = "Security group for web server"
  vpc_id      = aws_vpc.lab_vpc.id
}

# --- Web Server Instance ---
resource "aws_instance" "web_server" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              echo "Configuring Web App..."
              echo "RDS Endpoint: ${aws_db_instance.lab_db.endpoint}" > /var/www/html/db_info.txt
              EOF
}
