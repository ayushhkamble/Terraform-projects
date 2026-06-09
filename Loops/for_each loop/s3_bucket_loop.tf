variable "buckets" {
  default = {
    logs   = "company-logs"
    backup = "company-backup"
    media  = "company-media"
  }
}

resource "aws_s3_bucket" "bucket" {
  for_each = var.buckets

  bucket = each.value

  tags = {
    Name = each.key
  }
}