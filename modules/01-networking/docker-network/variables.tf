variable "name" {
  description = "Name of the Docker network"
  type        = string
}

variable "driver" {
  description = "Name of the network driver to use"
  type        = string
  default     = "bridge"
}

variable "internal" {
  description = "Restrict external access to the network if true"
  type        = bool
  default     = false
}

variable "attachable" {
  description = "Enable manual container attachment if true"
  type        = bool
  default     = true
}

variable "ipam_driver" {
  description = "Driver used for IP address management"
  type        = string
  default     = "default"
}

variable "subnet" {
  description = "Subnet in CIDR format that represents a network segment"
  type        = string
  default     = ""
}

variable "gateway" {
  description = "IPv4 or IPv6 gateway for the subnet"
  type        = string
  default     = ""
}

variable "ip_range" {
  description = "Range of IPs from which to allocate container IPs"
  type        = string
  default     = ""
}

variable "aux_address" {
  description = "Auxiliary IPv4 or IPv6 addresses used by the driver"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to add to the network"
  type        = map(string)
  default     = {}
}

variable "options" {
  description = "Network driver specific options"
  type        = map(string)
  default     = {}
}
