provider "aws" {
    region = "eu-north-1"
}
variable "instances"{
    default ={
       dev = "t3.micro"
       prod = "t3.small"
       test = "c7i-flex.large"
    }
}

resource "aws_instance" "my_ec2" {
    for_each = var.instances
    ami = "ami-05d62b9bc5a6ca605"
    instance_type = each.value

    tags = {
        Name = each.key
    }
}