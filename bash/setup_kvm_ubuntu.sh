
# just a record of the commands i'm using to setup kvm on ubuntu to have many small linux vms

# http://xmodulo.com/use-kvm-command-line-debian-ubuntu.html
sudo apt-get update
# http://askubuntu.com/questions/448358/automating-apt-get-install-with-assume-yes
sudo apt-get install kvm qemu-kvm libvirt-bin --assume-yes
sudo apt-get upgrade --assume-yes
