spoke_subnets = {
    primary = {
      private = true
      vpc_id  = "rick"
      cidr    = "10.1.1.0/24"
      mgmt    = false
    }
    database = {
      private = true
      vpc_id  = "rick"
      cidr    = "10.1.2.0/24"
      mgmt    = false
    }
    windows = {
      private = true
      vpc_id  = "morty"
      cidr    = "10.2.1.0/24"
      mgmt    = false
    }
    linux = {
      private = true
      vpc_id  = "morty"
      cidr    = "10.2.2.0/24"
      mgmt    = false
    }
    vault = {
      private = true
      vpc_id  = "birdperson"
      cidr    = "10.3.1.0/24"
      mgmt    = false
    }
    consul = {
      private = true
      vpc_id  = "birdperson"
      cidr    = "10.3.2.0/24"
      mgmt    = false
    }
    mgmt1 = {
      private = false
      vpc_id  = "rick"
      cidr    = "10.1.3.0/24"
      mgmt    = true
    }
    mgmt2 = {
      private = false
      vpc_id  = "morty"
      cidr    = "10.2.3.0/24"
      mgmt    = true
    }
    mgmt3 = {
      private = false
      vpc_id  = "birdperson"
      cidr    = "10.3.3.0/24"
      mgmt    = true
    }
  }
