# AWS

# Enable Swap File

https://github.com/aws/amazon-ssm-agent/issues/353
https://repost.aws/knowledge-center/ec2-memory-swap-file

```bash
sudo dd if=/dev/zero of=/swapfile bs=128M count=4  # 512 MB, e.g. t4g.nano
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
mount -a
```

# AWS Request for Reverse DNS (PTR) Record for SES Dedicated IP

https://repost.aws/questions/QUKR1nc2IyRXCUkjnacaw5EQ/request-for-reverse-dns-ptr-record-for-ses-dedicated-ip