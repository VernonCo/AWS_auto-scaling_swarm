resource "aws_s3_bucket" "scripts_bucket" {
  bucket = format("%s-%s-%s", var.bucket_name, var.namespace, var.environment)
  acl    = "private"

  versioning {
    enabled = true
  }
  # no encryption to be able to use etag
}

#  scripts to run on instance start up
resource "aws_s3_bucket_object" "file_upload1" {
  for_each = toset(var.script_uploads)
  bucket   = aws_s3_bucket.scripts_bucket.id
  key      = each.key
  source   = each.key
  # etag to catch changes to file and upload
  etag = filemd5(each.key)
}

# swarm deploy scripts ran by initial master
resource "aws_s3_bucket_object" "file_upload2" {
  for_each = toset(var.swarm_script_uploads)
  bucket   = aws_s3_bucket.scripts_bucket.id
  key      = format("scripts/%s", each.key)
  source   = format("example_scripts/%s", each.key)
  # etag to catch changes to file and upload
  etag = filemd5(format("example_scripts/%s", each.key))
}

# swarm stacks used by the deploy scripts ran by initial master
resource "aws_s3_bucket_object" "file_upload3" {
  for_each = toset(var.swarm_stack_uploads)
  bucket   = aws_s3_bucket.scripts_bucket.id
  key      = format("scripts/stacks/%s", each.key)
  source   = format("example_scripts/stacks/%s", each.key)
  # etag to catch changes to file and upload
  etag = filemd5(format("example_scripts/stacks/%s", each.key))
}

# container pem to allow access to other containers if needed.
resource "aws_s3_bucket_object" "file_upload" {
  count  = var.has_pem ? 1 : 0
  bucket = aws_s3_bucket.scripts_bucket.id
  key    = format("%s.pem", var.aws_key_name)
  source = format("%s.pem", var.aws_key_name)
  # etag to catch changes to file and upload
  etag = filemd5(format("%s.pem", var.aws_key_name))
}
