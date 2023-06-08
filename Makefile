default: run

ip:
	terraform show | grep "public_ip"

init:
	terraform init

run: init
	terraform apply
