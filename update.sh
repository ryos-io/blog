#!/bin/bash

cd /root/ryos-site && git pull origin master >> /var/log/ryos-pull.out
cd /root/ryos-site && jekyll build >> /var/log/jekyll.out
