#!/bin/bash

insight() {

  STATUS=$(insights-client --status);
  CHECKS="Registered at"

  if [[ "$STATUS" == *"$CHECKS"* ]]; then
    echo "System is Registered"
  else
    sudo insights-client --register;
  fi
}

grub2() {

  STRING=$( cat /etc/default/grub )
  CHECKS="GRUB_DISABLE_OS_PROBER"

  if [[ "$STRING" == *"$CHECKS"* ]]; then
    echo "OS Prober disable"
  else
    echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub
  fi

  sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub &&
  grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg;

}

firewalld() {

  CORESYS=$(firewall-cmd --get-active-zones | grep "coresys" | wc -c ) &&
  SYSADMS=$(firewall-cmd --get-active-zones | grep "sysadm" | wc -c ) &&
  
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


  SOURCE1=$(firewall-cmd --zone=coresys --list-all | grep "sources") &&
  SOURCE2=$(firewall-cmd --zone=sysadm --list-all | grep "sources") &&
  CHECK1="172.27.5.81" &&
  CHECK2="172.27.5.71" &&
  CHECK2="172.27.5.72" &&

  if [[ "$SOURCE1" == *"$CHECK1"* ]]; then
    echo "Firewall zone coresys is configured";
  else
    sudo firewall-cmd --permanent --zone="coresys" --add-source=172.27.5.81/24 &&
    sudo firewall-cmd --permanent --zone="coresys" --remove-service=cockpit &&
    sudo firewall-cmd --permanent --zone="coresys" --add-service=ssh &&
    sudo firewall-cmd --permanent --zone="coresys" --add-service=https;
  fi


  if [[ "$SOURCE2" == *"$CHECK2"* ]]; then
    echo "Firewall zone coresys first admin is configured";
  else
    sudo firewall-cmd --permanent --zone="sysadm" --add-source=172.27.5.71/24 &&
    sudo firewall-cmd --permanent --zone="sysadm" --remove-service=cockpit &&
    sudo firewall-cmd --permanent --zone="sysadm" --add-service=https;
  fi


  if [[ "$SOURCE2" == *"$CHECK3"* ]]; then
    echo "Firewall zone coresys second admin is configured";
  else
    sudo firewall-cmd --permanent --zone="sysadm" --add-source=172.27.5.72/24;
  fi

  sudo firewall-cmd --reload;
}

cockpit() {

  sudo systemctl enable --now cockpit.socket &&

  if [ -d "/etc/systemd/system/cockpit.socket.d/" ]; then
    echo "cockpit socket directory exist";
  else
    mkdir /etc/systemd/system/cockpit.socket.d/
  fi

  if [ -f "/etc/systemd/system/cockpit.socket.d/listen.conf" ]; then
    echo "cockpit listen config exist";
  else
    touch /etc/systemd/system/cockpit.socket.d/listen.conf
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
  sudo systemctl daemon-reload &&
  sudo systemctl restart cockpit.socket
}

podman() {
  dnf remove cockpit-podman -y &&
  dnf remove podman -y;
}

virtualization() {
  dnf groupinstall "virtualization host" -y &&
  dnf install cockpit-machines -y &&
  systemctl enable --now libvirtd;
}

insight && grub2 && firewalld && cockpit && podman && virtualization
