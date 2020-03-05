data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
    allowed_ip = "${chomp(data.http.myip.body)}/32"
}