variable "iam_users" {
    default = {
        ayush = "devops"
        yogesh = "developer"
        aniket = "tester"
    }
}
resource "aws_iam_user" "my_iam_user" {
    for_each = var.iam_users
    name = each.key

    tags ={
        Department = each.value
    }
}