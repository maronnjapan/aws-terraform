terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}








resource "aws_vpc" "sample-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sample-vpc"
  }
}

resource "aws_subnet" "sample-subnet-public01" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.0.0/20"
  tags = {
    Name = "sample-subnet-public01"
  }
}

resource "aws_subnet" "sample-subnet-private01" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.64.0/20"
  tags = {
    Name = "sample-subnet-private01"
  }
}

resource "aws_subnet" "sample-subnet-public02" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.16.0/20"
  tags = {
    Name = "sample-subnet-public02"
  }
}

resource "aws_subnet" "sample-subnet-private02" {
  vpc_id            = aws_vpc.sample-vpc.id
  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.80.0/20"
  tags = {
    Name = "sample-subnet-private02"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sample-vpc.id

  tags = {
    Name = "sample-igw"
  }
}

resource "aws_eip" "elastic-ip-01" {
  domain = "vpc"
}


resource "aws_nat_gateway" "sample-ngw-01" {
  allocation_id = aws_eip.elastic-ip-01.id
  subnet_id     = aws_subnet.sample-subnet-public01.id

  tags = {
    Name = "sample-ngw-01"
  }
}

resource "aws_eip" "elastic-ip-02" {
  domain = "vpc"

}


resource "aws_nat_gateway" "sample-ngw-02" {
  allocation_id = aws_eip.elastic-ip-02.id
  subnet_id     = aws_subnet.sample-subnet-public02.id

  tags = {
    Name = "sample-ngw-02"
  }
}


resource "aws_route_table" "sample-rtb-public" {
  vpc_id = aws_vpc.sample-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "sample-rtb-public"
  }
}

resource "aws_route_table_association" "relate-public-route-table1" {
  subnet_id      = aws_subnet.sample-subnet-public01.id
  route_table_id = aws_route_table.sample-rtb-public.id
}
resource "aws_route_table_association" "relate-public-route-table2" {
  subnet_id      = aws_subnet.sample-subnet-public02.id
  route_table_id = aws_route_table.sample-rtb-public.id
}


resource "aws_route_table" "sample-rtb-private01" {
  vpc_id = aws_vpc.sample-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sample-ngw-01.id
  }

  tags = {
    Name = "sample-rtb-private01"
  }
}

resource "aws_route_table_association" "relate-private-route-table1" {
  subnet_id      = aws_subnet.sample-subnet-private01.id
  route_table_id = aws_route_table.sample-rtb-private01.id
}

resource "aws_route_table" "sample-rtb-private02" {
  vpc_id = aws_vpc.sample-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sample-ngw-02.id
  }

  tags = {
    Name = "sample-rtb-private02"
  }
}

resource "aws_route_table_association" "relate-private-route-table2" {
  subnet_id      = aws_subnet.sample-subnet-private02.id
  route_table_id = aws_route_table.sample-rtb-private02.id
}


resource "aws_security_group" "sample-sg-bastion-terraform" {
  name        = "sample-sg-bastion-terraform"
  description = "for bastion server"
  vpc_id      = aws_vpc.sample-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sample-sg-elb-terraform" {
  name        = "sample-sg-elb-terraform"
  description = "for load balancer"
  vpc_id      = aws_vpc.sample-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.sample-vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}








variable "key_name" {
  type        = string
  description = "keypair name"
  #キーペア名はここで指定
  default = "hoge-key"
}

locals {
  public_key_file  = "./.key_pair/${var.key_name}.id_rsa.pub"
  private_key_file = "./.key_pair/${var.key_name}.id_rsa"
}

#privateキーのアルゴリズム設定
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#local_fileのリソースを指定するとterraformを実行するディレクトリ内でファイル作成やコマンド実行が出来る。
resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh
  provisioner "local-exec" {
    command = "chmod 600 ${local.public_key_file}"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.keygen.public_key_openssh

  provisioner "local-exec" {
    # command = <<-EOT
    #   echo "${tls_private_key.keygen.private_key_pem}" > ~/.ssh/${var.key_name}.pem
    # EOT
    command = <<-EOT
     echo "${tls_private_key.keygen.private_key_pem}" > /mnt/c/Users/tihou/.ssh/${var.key_name}.pem
    EOT
  }
}

data "aws_ami" "amzlinux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_instance" "sample-ec2-bastion" {
  ami             = data.aws_ami.amzlinux2.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.sample-subnet-public01.id
  security_groups = [aws_security_group.sample-sg-bastion-terraform.id, aws_default_security_group.default.id]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name

  tags = {
    Name = "sample-ec2-bastion"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}


resource "aws_instance" "sample-ec2-web01" {
  ami             = data.aws_ami.amzlinux2.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.sample-subnet-private01.id
  security_groups = [aws_security_group.sample-sg-bastion-terraform.id, aws_default_security_group.default.id]

  associate_public_ip_address = false
  key_name                    = aws_key_pair.key_pair.key_name

  tags = {
    Name = "sample-ec2-web01"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "sample-ec2-web02" {
  ami             = data.aws_ami.amzlinux2.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.sample-subnet-private02.id
  security_groups = [aws_default_security_group.default.id]

  associate_public_ip_address = false
  key_name                    = aws_key_pair.key_pair.key_name

  tags = {
    Name = "sample-ec2-web02"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}


#local_fileのリソースを指定するとterraformを実行するディレクトリ内でファイル作成やコマンド実行が出来る。
resource "local_file" "config_file" {
  filename = "/mnt/c/Users/tihou/.ssh/config"
  content  = <<-EOT
Host bastion
    Hostname ${aws_instance.sample-ec2-bastion.public_ip}
    User ec2-user
    IdentityFile ~/.ssh/hoge-key.pem

Host web01
    Hostname ${aws_instance.sample-ec2-web01.private_ip}
    User ec2-user
    IdentityFile ~/.ssh/hoge-key.pem
    ProxyCommand ssh.exe -W %h:%p bastion

Host web02
    Hostname ${aws_instance.sample-ec2-web02.private_ip}
    User ec2-user
    IdentityFile ~/.ssh/hoge-key.pem
    ProxyCommand ssh.exe -W %h:%p bastion
    EOT
  # provisioner "local-exec" {
  #   command = "chmod 600 ~/.ssh/config"
  # }
}



//ALB
resource "aws_lb" "sample-elb-terraform" {
  name               = "sample-elb-terraform"
  internal           = false
  load_balancer_type = "application"
  //アプリケーションタイプのロードバランサーに対してのみ有効
  security_groups = [aws_security_group.sample-sg-elb-terraform.id, aws_default_security_group.default.id]
  subnets         = [aws_subnet.sample-subnet-public01.id, aws_subnet.sample-subnet-public02.id]
  ip_address_type = "ipv4"
}

// ターゲットグループ
resource "aws_lb_target_group" "sample-tg-terraform" {
  name     = "sample-tg-terraform"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.sample-vpc.id
}

// ターゲットグループにEC2インスタンスを登録
//1台目のEC2インスタンスに登録
resource "aws_lb_target_group_attachment" "sample-target_ec01" {
  target_group_arn = aws_lb_target_group.sample-tg-terraform.arn
  target_id        = aws_instance.sample-ec2-web01.id
}
//2台目のEC2インスタンスに登録
resource "aws_lb_target_group_attachment" "sample-target_ec02" {
  target_group_arn = aws_lb_target_group.sample-tg-terraform.arn
  target_id        = aws_instance.sample-ec2-web02.id
}

// リスナー設定
resource "aws_lb_listener" "sample-tg" {
  load_balancer_arn = aws_lb.sample-elb-terraform.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sample-tg-terraform.arn
  }
}

