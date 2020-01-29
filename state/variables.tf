variable "terraform_state_bucket" {
  description = "Bucket name to hold terraform state"
  type        = string
  default     = "yourcompany-terraform-state"
}

variable "dynamodb_lock_table_name" {
  description = "Dynamodb table name to hold terraform state lock"
  type        = string
  default     = "terraform-locks"
}

variable "create_bucket" {
  description = "Create the bucket?"
  type        = bool
  default     = true
}

variable "create_lock_table" {
  description = "Create the lock table?"
  type        = bool
  default     = true
}

variable "region-1" {
  description = "region for dynamodb table"
  type        = string
  default     = "us-east-2"
}

variable "region-2" {
  description = "region for dynamodb table"
  type        = string
  default     = "us-west-2"
}
