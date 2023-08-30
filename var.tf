variable "subnet_details" {
  type = list(string)

}
variable "resource_group_details" {
  type = object({
    name     = string
    location = string
  })

}
variable "publicip" {
  type = list(string)

}
variable "nic" {
  type = list(string)

}
variable "vms" {
  type = list(string)

}
variable "disk_names" {
  type = list(string)

}
variable "addressspace" {
  type = list(string)

}

variable "nisga" {
  type = list(string)

}

variable "netsecgroup" {
  type = string

}

variable "trig" {
  type = string

}

variable "usern" {
  type = string
}

variable "pass" {
  type = string

}