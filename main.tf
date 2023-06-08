provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "minecraft-server" {
  ami           = "ami-080f7286ffdf988ee"
  instance_type = "t3.small"
  key_name      = "minecraft"

  user_data = file("user-data.sh")

  tags = {
    Name = "Final Minecraft Server"
  }

  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-sg"
  description = "Security group for Minecraft server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minecraft-sg"
  }
}
