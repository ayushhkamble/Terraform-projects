provider "aws" {
    region = "eu-north-1"
}
variable "ami_id" {
    description = "The AMI ID for the EC2 instance"
    type = string
    default = "ami-05d62b9bc5a6ca605"
}
variable "instance_type" {
    description = "The instance type for the EC2 instance"
    type = string
    default = "t3.micro"
}
resource "aws_instance" "my_ec2" {
    count = 3
    ami = var.ami_id
    instance_type = var.instance_type

    tags = {
        Name = "MyEC2Instance-${count.index}"
    }
}