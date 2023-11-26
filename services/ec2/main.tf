module "vpc-module" {
  source = "../vpc"
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
  subnet_id       = module.vpc-module.sample-subnet-public01-id
  security_groups = [module.vpc-module.sample-sg-bation-id, module.vpc-module.default-security-groups-id]

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
  subnet_id       = module.vpc-module.sample-subnet-private01-id
  security_groups = [module.vpc-module.default-security-groups-id, module.vpc-module.sample-sg-bation-id]

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
  subnet_id       = module.vpc-module.sample-subnet-private02-id
  security_groups = [module.vpc-module.default-security-groups-id]

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
  # filename = "/home/tihoutaikai2011/.ssh/config"
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
  security_groups = [module.vpc-module.default-security-groups-id, module.vpc-module.sample-security-group-elb-id]
  subnets = [module.vpc-module.sample-subnet-public01-id,
  module.vpc-module.sample-subnet-public02-id]
  ip_address_type = "ipv4"
}

// ターゲットグループ
resource "aws_lb_target_group" "sample-tg-terraform" {
  name     = "sample-tg-terraform"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc-module.sample-vpc-id
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
