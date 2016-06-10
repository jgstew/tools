
# just a record of the commands i'm using to setup kvm on ubuntu to have many small linux vms
# https://help.ubuntu.com/community/KVM/CreateGuests
# http://xmodulo.com/use-kvm-command-line-debian-ubuntu.html
sudo apt-get update
# http://askubuntu.com/questions/448358/automating-apt-get-install-with-assume-yes
sudo apt-get install kvm qemu-kvm libvirt-bin qemu --assume-yes
sudo apt-get upgrade --assume-yes

qemu-img create -f qcow2 debian.img 1500M
# https://en.wikibooks.org/wiki/QEMU/Networking
qemu-system-i386 -cdrom debian-live.iso -m 400 -smp 1 -redir udp:52311::52311 debian.img

#  REFERENCES:
# http://raspberrypi.stackexchange.com/questions/4296/can-i-emulate-x86-cpu-to-run-teamspeak-3-server
# http://bochs.sourceforge.net/
