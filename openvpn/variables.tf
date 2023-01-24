variable "test_openvpn" {
  type    = bool
  default = true
}

variable "openvpn_ami" {
  description = "version 2.8.5 of openvpn access server official"
  type        = string
  default     = "ami-037ff6453f0855c46"
}

variable "server_username" {
  description = "openvpn server initial credentials"
  type        = string
  sensitive   = true
  default     = "openvpn"
}

variable "server_password" {
  description = "openvpn server initial credentials"
  type        = string
  sensitive   = true
  default     = "password"
}