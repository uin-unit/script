#!/bin/bash

insight() {
  sudo insights-client --register;
}

grub2() {
  sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub &&
  echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub &&
  grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg;
}


firewalld() {

  CORESYS=$(firewall-cmd --get-active-zones | grep "coresys" | wc -c );
  SYSADMS=$(firewall-cmd --get-active-zones | grep "sysadm" | wc -c );

  if [ $CORESYS -gt 0 ]; then
    echo "zone exist";
  else
    sudo firewall-cmd --permanent --new-zone=coresys;
  fi

  if [ $SYSADMS -gt 0 ]; then
    echo "zone exist";
  else
    sudo firewall-cmd --permanent --new-zone=sysadm;
  fi

  sudo firewall-cmd --permanent --zone="coresys" --add-source=172.27.5.81/24 &&
  sudo firewall-cmd --permanent --zone="coresys" --add-service=ssh &&

  sudo firewall-cmd --permanent --zone="sysadm" --add-source=172.27.5.71/24 &&
  sudo firewall-cmd --permanent --zone="sysadm" --add-source=172.27.5.72/24 &&

  sudo firewall-cmd --reload;
}


cockpit() {

  if [ -d "/etc/systemd/system/cockpit.socket.d/" ]; then
    echo "cockpit socket directory exist";
  else
    mkdir /etc/systemd/system/cockpit.socket.d/;
  fi

  if [ -f "/etc/systemd/system/cockpit.socket.d/listen.conf" ]; then
    echo "cockpit listen config exist";
  else
    touch /etc/systemd/system/cockpit.socket.d/listen.conf;
  fi

  if [ -f "/etc/cockpit/cockpit.conf" ]; then
    echo "cockpit main config file exist";
  else
    touch /etc/cockpit/cockpit.conf;
  fi
  

  echo "[Socket]" > /etc/systemd/system/cockpit.socket.d/listen.conf &&
  echo "ListenStream=" >> /etc/systemd/system/cockpit.socket.d/listen.conf &&
  echo "ListenStream=443" >> /etc/systemd/system/cockpit.socket.d/listen.conf &&

  echo "[WebService]" > /etc/cockpit/cockpit.conf &&
  echo "LoginTitle=Fakultas Adab dan Humaniora" >> /etc/cockpit/cockpit.conf &&
  echo "LoginTo=false" >> /etc/cockpit/cockpit.conf &&

  sudo semanage port -m -t websm_port_t -p tcp 443 &&

  sudo firewall-cmd --permanent --zone="coresys" --permanent --add-service=https &&
  sudo firewall-cmd --permanent --zone="sysadm" --permanent --add-service=https &&
  sudo firewall-cmd --permanent --zone="sysadm" --permanent --remove-service=cockpit &&
  sudo firewall-cmd --permanent --zone="public" --permanent --remove-service=cockpit &&
  sudo firewall-cmd --reload &&
  
  sudo systemctl daemon-reload &&
  sudo systemctl restart cockpit.socket
}


podman() {
  dnf remove cockpit-podman -y &&
  dnf remove podman -y;
}


virtualization_host() {
  dnf groupinstall "virtualization host" -y &&
  dnf install cockpit-machines -y &&
  systemctl enable --now libvirtd;
}


insight && grub2 && firewalld && cockpit && podman && virtualization_host
