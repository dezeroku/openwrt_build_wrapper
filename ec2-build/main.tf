resource "aws_security_group" "ingress-ssh" {
  name = "allow-ssh-openwrt-builder"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = ["al2022-ami-ecs-hvm*"]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "openwrt_builder_ssh_key"
  public_key = file(var.ssh_pub_key_path)
}

resource "aws_spot_instance_request" "openwrt_builder" {
  ami                  = data.aws_ami.amazon_linux.id
  spot_price           = var.spot_price
  instance_type        = var.instance_type
  spot_type            = "one-time"
  wait_for_fulfillment = "true"
  key_name             = "openwrt_builder_ssh_key"

  vpc_security_group_ids = ["${aws_security_group.ingress-ssh.id}"]
  tags = {
    Purpose = "OpenWRTBuilder"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.ssh_priv_key_path)
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /tmp/bootstrap.sh"
    ]
  }
}
