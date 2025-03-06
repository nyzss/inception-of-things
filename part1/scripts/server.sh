curl -sfL https://get.k3s.io | sh -

mkdir -p /vagrant_shared

touch /vagrant_shared/token

cat /var/lib/rancher/k3s/server/token > /vagrant_shared/token

