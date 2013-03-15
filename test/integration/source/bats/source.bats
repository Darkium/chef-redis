#!/usr/bin/env bats

@test "It should create the log directory" {
   [ -d /var/log/redis ]
}

@test "It should add slaveof to server.conf" {
  grep 'slaveof 198.18.0.1 6379' /etc/redis/server.conf              
}
