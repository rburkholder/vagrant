if [[ "2" != "$#" ]]; then
  echo need KRNLVER VBOXVER
else
  KRNLVER=$1
  VBOXVER=$2
  vagrant up --provision-with newkernel
  SYNC_DISABLED=true vagrant reload --provision-with newadditions
  vagrant reload --provision-with fixkey
  echo "manual steps:"
  echo "perform packaging step, then... "
  echo "# vagrant destroy"
  fi
