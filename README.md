# CS312 Final Project

## Background

In this project, we will be deploying a minecraft server on an AWS instance using a infrastructure provisioning script, in this case Terraform.

## Steps

- Install needed cli tools
- Get and setup AWS credentials
- Create Terraform script
  - Create user-data shell script
- Run Terraform script
- Play Minecraft on your brand new server!

## Tools needed

The tools needed for this project are [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

After installation, verify these tools were downloaded properly by opening a terminal and entering

```bash
terraform --version
```

```bash
aws --version
```

If you get versions back that means they were installed correctly. If you get `command not found` that means they were not installed correctly.

## Terraform Setup

Terraform will be the main tool used for this project. To first get started you will need to get your credentials from AWS which include `AWS Access Key ID`, `AWS Secret Access Key`, and `AWS Session Token`. AWS should give you all of these in a section and copy them and then create a credential file in the aws folder as such:

```bash
cd ~
mkdir .aws
cd ./mkdir
touch credentials
```

and insert the credentials into the file:

```bash
vim credentials
```

The credentials will look like

```bash
[default]
aws_access_key_id=XX
aws_secret_access_key=XX
aws_session_token=XX
```

with the `XX` being your AWS credentials.

Now you will want to export your access key id and secret access key using

```bash
export AWS_ACCESS_KEY_ID=XX
```

```bash
export AWS_SECRET_ACCESS_KEY=XX
```

with the `XX` being the id and key respectively. These can be found in the credentials file you just made.

## Terraform Script

Create a folder for the Terraform script and filders and files it creates

```bash
mkdir ./minecraft-server-setup
cd ./minecraft-server-setup
```

Now you will want to make the terraform script and another script file that the Terraform script will use

```bash
touch main.tf
touch user-data.sh
```

Now edit the Terraform script

```bash
vim main.tf
```

and enter the following:

```terraform
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
```

In this script the `provider` section states that we want to use AWS and `region` indicates which region we want the AWS instance to be in. You can choose whichever region is best for you.

The `resource "aws_instance"` section indicates how the instance will be setup. The `ami` indicates what machine image will be used, at the time of creation it is the latest Amazon Linux image. The `instance_type` is the type of machine that will be used. Based on what you are doing with your server, you could use a higher tier instance type to get more vCPUs and RAM. The `key_name` is the ssh key that will be allowed to connect to the instance. Pick an instance key you have made in AWS and use that key. In my case I have a key named `minecraft.pem` so I put `minecraft` as my `key_name`. The `user_data` is a script that will be run on the startup of the the instance which will be covered later. The `vpc_security_group_ids` is the security group that will be created later in the script.

the `resource "aws_security_group"` section is the security group that will be created for this instance. There are two `ingress` sections which are the inbound rules of the instance. The first ingress rull is for port 22 and `cidr_blocks = ["0.0.0.0/0"]` which allow for SSH from any IP address. If you want only your IP address to be able to SSH into the instance you can change `["0.0.0.0/0"]` to `["your_ip"]`. The second `ingress` rule opens the port 25565 to anyone which is the port that minecraft servers use.

After configuring the script, save the file and now edit the `user-data.sh` script

```bash
vim user-data.sh
```

and insert the following into the shell script

```bash
#!/bin/bash
yum update -y
yum install -y java-17-amazon-corretto

cd /home/ec2-user
mkdir minecraft
cd ./minecraft
mkdir server
cd ./server
wget https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar

echo "eula=true" >/home/ec2-user/minecraft/server/eula.txt

cat >/etc/systemd/system/minecraft.service <<EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=simple
ExecStart=sudo java -Xmx1024M -Xms1024M -jar server.jar nogui
WorkingDirectory=/home/ec2-user/minecraft/server
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable minecraft.service
systemctl start minecraft.service
```

The first section of the shell script updates the repositories and then installs java to allow the minecraft server to run.

The second section created a folder for the server to live in and then `wgets` the `server.jar` file. At the time of the project, the url that is being downloaded is for Minecraft 1.19.4. To get the latest server file visit [Minecraft](https://www.minecraft.net/en-us/download/server) and get the url for the latest server file.

The next line `echo`s `eula=true` into a file named `eula.txt` to ensure that our server will run.

The next section with `cat` creats a systemd service so that when our instance starts up, our minecraft server will automatically be run. In the line that starts with `ExecStart` the server is being run with 1 GiB of memory. If you have a larger instance type, such as `t4.large` you can run the server with more ram, but make sure to leave ram for the OS to run.

Finally the last section with `systemctl` enables and starts our service to start the Minecraft server.

## Running the Script

First you will want to initialize Terraform to install all of the dependencies that are in your script

```bash
terraform init
```

Then you will want to format the script to make sure it has the correct formatting using

```bash
terraform fmt
```

Then you will want to make sure the script is syntatically valid using

```bash
terraform validate
```

If the validation passes, you are ready to run the script using

```bash
terraform apply
```

This will print out what terraform will create and will prompt you to enter whether or not to perform the action. Typing in `yes` and pressing enter will create the instance. After applying and running the script, your AWS instance will be created. Your instance will take a few minutes to fully initialize and when it is done you will have a working Minecraft server!

## Connecting to the Server

To get the IP address and connect to the server enter the following

```bash
terraform show | grep "public_ip"
```

This will output the public IP of the instance which should look like `XX.XX.XX.XX`. Copy this IP address and open Minecraft connect to your new server. On the first startup of the instance, it may take a while for the server to start working as Minecraft service needs to initialize the entire server.

## Play Minecraft

Now you have your very own minecraft server hosted by AWS. Share the IP address with some friends and have fun!
